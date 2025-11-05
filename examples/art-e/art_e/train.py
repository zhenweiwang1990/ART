import os
import sys

# Load .env FIRST - before any other imports
# This ensures WANDB_API_KEY and other env vars are available to all modules
from dotenv import load_dotenv
load_dotenv()

# Set environment variables before importing art
# Enable unsloth for optimal training performance on Linux/CUDA systems
# Set IMPORT_UNSLOTH=0 only if unsloth is unavailable or you encounter issues
os.environ.setdefault("IMPORT_UNSLOTH", "1")

import art
import asyncio
from typing import List
from rollout import rollout
from art_e.data.query_iterators import load_synthetic_queries
from art_e.data.types_enron import SyntheticQuery
from art_e.data.local_email_db import generate_database
from art.utils import iterate_dataset
from art_e.project_types import ProjectPolicyConfig, TrainingConfig
from art_e.evaluate.benchmark import benchmark_model

# First, I defined a trainable model. The `ProjectPolicyConfig` contains the
# specific parameters I varied between runs for this project. They're
# interpreted in the rollout defined in `rollout.py` and used to control
# generation.
agent_002 = art.TrainableModel(
    name="email-agent-002",
    project="email_agent",
    base_model="Qwen/Qwen2.5-7B-Instruct",
    config=ProjectPolicyConfig(
        max_turns=10,
        log_to_openpipe=True,
        training_config=TrainingConfig(
            trajectories_per_group=6,
            groups_per_step=8,
            learning_rate=1.2e-5,
            eval_steps=30,
            val_set_size=100,
            training_dataset_size=4000,
            num_epochs=1,
        ),
    ),
)

# While running experiments,
agent_004 = agent_002.model_copy(deep=True)
assert isinstance(agent_004.config, ProjectPolicyConfig)
agent_004.name = "email-agent-004"
agent_004.config.max_turns = 30

agent_005 = agent_002.model_copy(deep=True)
assert isinstance(agent_005.config, ProjectPolicyConfig)
agent_005.name = "email-agent-005"

agent_006 = agent_005.model_copy(deep=True)
agent_006.name = "email-agent-006"

agent_007 = agent_005.model_copy(deep=True)
agent_007.name = "email-agent-007"
assert isinstance(agent_007.config, ProjectPolicyConfig)
agent_007.config.use_tools = True

agent_008 = agent_005.model_copy(deep=True)
agent_008.name = "email-agent-008"
assert isinstance(agent_008.config, ProjectPolicyConfig)
assert agent_008.config.training_config is not None
agent_008.config.use_tools = True
agent_008.config.training_config.trajectories_per_group = 4
agent_008.config.training_config.groups_per_step = 12
agent_008.config.training_config.num_epochs = 3

agent_011 = agent_008.model_copy(deep=True)
agent_011.name = "email-agent-011"
assert isinstance(agent_011.config, ProjectPolicyConfig)
assert agent_011.config.training_config is not None
agent_011.config.training_config.num_epochs = 4

agent_012 = agent_008.model_copy(deep=True)
agent_012.name = "email-agent-012"

agent_013 = agent_002.model_copy(deep=True)
agent_013.name = "email-agent-013"
assert isinstance(agent_013.config, ProjectPolicyConfig)
assert agent_013.config.training_config is not None
agent_013.config.training_config.num_epochs = 4
agent_013.config.training_config.trajectories_per_group = 4
agent_013.config.training_config.groups_per_step = 24

agent_014 = agent_008.model_copy(deep=True)
agent_014.name = "email-agent-014"
assert isinstance(agent_014.config, ProjectPolicyConfig)
agent_014.config.stupid_simple_reward_fn = True


# Qwen2.5-14B (QLoRA via Unsloth) – memory-aware defaults
# - Use 4bit loading (default in ART dev model config)
# - Reduce per-step group size for 14B to keep VRAM in check
# - You can bump these once confirmed stable on your GPU
agent_qwen3_14b = art.TrainableModel(
    name="email-agent-qwen25-14b",
    project="email_agent",
    base_model="Qwen/Qwen2.5-14B-Instruct",
    config=ProjectPolicyConfig(
        max_turns=30,
        use_tools=True,
        training_config=TrainingConfig(
            trajectories_per_group=3,   # 2–4 recommended for 14B
            groups_per_step=8,          # 8–12; raise cautiously if VRAM allows
            learning_rate=1.0e-5,       # good starting LR for GRPO + LoRA
            eval_steps=30,
            val_set_size=100,
            training_dataset_size=4000,
            num_epochs=1,
        ),
    ),
)


async def run_training(model: art.TrainableModel):
    generate_database()

    assert isinstance(model.config, ProjectPolicyConfig)
    if model.config.training_config is None:
        raise ValueError("Training config is not set")
    api = art.LocalAPI()
    await model.register(api)
    
    # Optional S3 sync - only if BACKUP_BUCKET is set
    backup_bucket = os.environ.get("BACKUP_BUCKET")
    if backup_bucket:
        print(f"Pulling from S3 bucket: `{backup_bucket}`")
        await api._experimental_pull_from_s3(
            model,
            s3_bucket=backup_bucket,
            verbose=True,
        )
    else:
        print("No BACKUP_BUCKET set - using local storage only")

    print("Loading training data...")
    train_scenarios: List[SyntheticQuery] = load_synthetic_queries(
        split="train", limit=model.config.training_config.training_dataset_size
    )
    print("Loading validation data...")
    val_scenarios: List[SyntheticQuery] = load_synthetic_queries(
        split="test", limit=model.config.training_config.val_set_size
    )

    print(f"Training data size: {len(train_scenarios)}")
    print(f"Validation data size: {len(val_scenarios)}")

    train_iterator = iterate_dataset(
        train_scenarios,
        groups_per_step=model.config.training_config.groups_per_step,
        num_epochs=model.config.training_config.num_epochs,
        initial_step=await model.get_step(),
    )

    for batch, epoch, global_step, epoch_step in train_iterator:
        if global_step % model.config.training_config.eval_steps == 0:
            print(f"\n--- Evaluating at Iteration {global_step} ---")
            await benchmark_model(model)
            await model.delete_checkpoints()
            
            # Optional S3 backup
            if backup_bucket:
                print(f"Backing up to S3 bucket: {backup_bucket}")
                await api._experimental_push_to_s3(
                    model,
                    s3_bucket=backup_bucket,
                )
            else:
                print("Checkpoints saved locally (no S3 backup)")

        groups = await art.gather_trajectory_groups(
            (
                art.TrajectoryGroup(
                    (
                        rollout(model, scenario)
                        for _ in range(
                            model.config.training_config.trajectories_per_group
                        )
                    )
                )
                for scenario in batch
            )
        )

        await model.train(
            groups,
            config=art.TrainConfig(
                learning_rate=model.config.training_config.learning_rate
            ),
        )

    await benchmark_model(model)
    
    # Final S3 backup (optional)
    if backup_bucket:
        print(f"Final backup to S3 bucket: {backup_bucket}")
        await api._experimental_push_to_s3(
            model,
            s3_bucket=backup_bucket,
        )
    else:
        print("Model weights saved locally (no S3 backup)")
    
    print("Training finished.")


if __name__ == "__main__":
    import os

    config = None
    training_config = os.environ.get("RUN_ID")
    if training_config == "002":
        config = agent_002
    elif training_config == "004":
        config = agent_004
    elif training_config == "005":
        config = agent_005
    elif training_config == "006":
        config = agent_006
    elif training_config == "007":
        config = agent_007
    elif training_config == "008":
        config = agent_008
    elif training_config == "011":
        config = agent_011
    elif training_config == "012":
        config = agent_012
    elif training_config == "013":
        config = agent_013
    elif training_config == "014":
        config = agent_014
    elif training_config == "QWEN3_14B":
        config = agent_qwen3_14b
    else:
        raise ValueError(f"Invalid RUN_ID: {training_config}")

    asyncio.run(run_training(config))
