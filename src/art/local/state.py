import asyncio
from contextlib import asynccontextmanager
from dataclasses import asdict
import gc
import os

# Conditionally import unsloth based on IMPORT_UNSLOTH environment variable
# Set IMPORT_UNSLOTH=0 to skip unsloth (useful for non-Linux or debugging)
if os.environ.get("IMPORT_UNSLOTH", "1") == "1":
    try:
        import unsloth  # type: ignore
    except ImportError:
        print("Warning: unsloth not available, continuing without it")
        unsloth = None  # type: ignore
else:
    unsloth = None  # type: ignore

from datasets import Dataset
import nest_asyncio
import peft
import torch
from transformers.tokenization_utils_base import PreTrainedTokenizerBase
from transformers.utils.dummy_pt_objects import (
    PreTrainedModel,
    GenerationMixin,
)
from trl import GRPOConfig, GRPOTrainer
from typing import Any, AsyncGenerator, cast, TYPE_CHECKING
from vllm.engine.async_llm_engine import AsyncLLMEngine
from vllm.engine.arg_utils import AsyncEngineArgs
from vllm.worker.worker_base import WorkerWrapperBase
from vllm.worker.multi_step_model_runner import MultiStepModelRunner

from ..dev.model import InternalModelConfig

if TYPE_CHECKING:
    from .service import TrainInputs

nest_asyncio.apply()


class CausallLM(PreTrainedModel, GenerationMixin):
    vllm_engine: AsyncLLMEngine


class ModelState:
    """
    A class responsible for initializing and holding references to the model and related state.
    """

    def __init__(self, config: InternalModelConfig) -> None:
        from vllm.engine import async_llm_engine
        from vllm.worker.multi_step_model_runner import MultiStepModelRunner

        # Patch MultiStepModelRunner for Unsloth compatibility
        if not hasattr(MultiStepModelRunner, "model"):
            MultiStepModelRunner.model = property(  # type: ignore
                lambda self: self._base_model_runner.model
            )

        # Set effectively unlimited timeout to support engine pausing & resumption
        async_llm_engine.ENGINE_ITERATION_TIMEOUT_S = 2**31 - 1
        # Sticking with V0 engine for now
        os.environ["VLLM_USE_V1"] = "0"
        # We can't use expandable segments with sleep mode
        enable_sleep_mode = config.get("engine_args", {}).get(
            "enable_sleep_mode", False
        )
        if enable_sleep_mode:
            os.environ["PYTORCH_CUDA_ALLOC_CONF"] = ""
        # Initialize Unsloth model
        # NOTE: We have to patch empty_cache with a no-op during model initialization
        # to avoid an allocator error.
        empty_cache = torch.cuda.empty_cache
        torch.cuda.empty_cache = lambda: None
        from_engine_args = AsyncLLMEngine.from_engine_args

        # NOTE: We also have to patch from_engine_args to control the engine args
        # that are passed to the engine constructor.
        def _from_engine_args(
            engine_args: AsyncEngineArgs, *args: Any, **kwargs: Any
        ) -> AsyncLLMEngine:
            engine_args_dict = asdict(engine_args)
            engine_args_dict.update(config.get("engine_args", {}))
            engine_args = AsyncEngineArgs(**engine_args_dict)
            return from_engine_args(engine_args, *args, **kwargs)

        AsyncLLMEngine.from_engine_args = _from_engine_args
        
        # Load model and tokenizer - use unsloth if available, otherwise standard transformers
        if unsloth is not None:
            self.model, self.tokenizer = cast(
                tuple[CausallLM, PreTrainedTokenizerBase],
                unsloth.FastLanguageModel.from_pretrained(**config.get("init_args", {})),
            )
        else:
            # Fallback to standard transformers/peft without unsloth optimizations
            from transformers import AutoModelForCausalLM, AutoTokenizer
            init_args = config.get("init_args", {}).copy()
            model_name = init_args.pop("model_name", None)
            if not model_name:
                raise ValueError("model_name required in init_args")
            
            # Filter out unsloth/vLLM-specific parameters that transformers doesn't recognize
            # Based on InitArgs in src/art/dev/model.py
            unsloth_vllm_only_params = {
                'max_seq_length', 'fast_inference', 'gpu_memory_utilization',
                'float8_kv_cache', 'random_state', 'max_lora_rank',
                'disable_log_stats', 'enable_prefix_caching', 'use_async',
                'full_finetuning', 'fix_tokenizer', 'use_gradient_checkpointing',
                'resize_model_vocab', 'use_exact_model_name', 'rope_scaling',
                'load_in_4bit', 'load_in_8bit', 'dtype'  # Handled separately via quantization_config
            }
            filtered_args = {k: v for k, v in init_args.items() if k not in unsloth_vllm_only_params}
            
            # Handle quantization config separately if needed
            if init_args.get('load_in_4bit') or init_args.get('load_in_8bit'):
                from transformers import BitsAndBytesConfig
                bnb_config = BitsAndBytesConfig(
                    load_in_4bit=init_args.get('load_in_4bit', False),
                    load_in_8bit=init_args.get('load_in_8bit', False),
                )
                filtered_args['quantization_config'] = bnb_config
            
            self.model = AutoModelForCausalLM.from_pretrained(model_name, **filtered_args)
            self.tokenizer = AutoTokenizer.from_pretrained(model_name)
        
        AsyncLLMEngine.from_engine_args = from_engine_args
        torch.cuda.empty_cache = empty_cache
        torch.cuda.empty_cache()
        self.vllm = vLLMState(self.model.vllm_engine, enable_sleep_mode)
        
        # Initialize PEFT model - use unsloth if available, otherwise standard peft
        if unsloth is not None:
            self.peft_model = cast(
                peft.peft_model.PeftModelForCausalLM,
                unsloth.FastLanguageModel.get_peft_model(
                    self.model, **config.get("peft_args", {})
                ),
            )
        else:
            # Fallback to standard peft
            from peft import get_peft_model, LoraConfig
            peft_args = config.get("peft_args", {})
            # Convert unsloth-style args to peft-style if needed
            if "r" in peft_args:
                lora_config = LoraConfig(**peft_args)
                self.peft_model = get_peft_model(self.model, lora_config)
            else:
                raise ValueError("peft_args must contain LoRA configuration")
        
        self.lora_model = cast(peft.tuners.lora.LoraModel, self.peft_model.base_model)
        # Initialize trainer
        data = {"prompt": ""}
        self.trainer = GRPOTrainer(
            model=self.peft_model,  # type: ignore
            reward_funcs=[],
            args=GRPOConfig(**config.get("trainer_args", {})),
            train_dataset=Dataset.from_list([data for _ in range(10_000_000)]),
            processing_class=self.tokenizer,
        )
        self.inputs_queue = asyncio.Queue["TrainInputs"]()

        # Patch trainer _prepare_inputs()
        def _async_prepare_inputs(*_, **__) -> dict[str, torch.Tensor]:
            async def get_inputs() -> "TrainInputs":
                return await self.inputs_queue.get()

            # Force otherwise synchronous _prepare_inputs() to yield
            # with nested asyncio.run() call
            inputs = asyncio.run(get_inputs())

            return cast(dict[str, torch.Tensor], inputs)

        self.trainer._prepare_inputs = _async_prepare_inputs


class vLLMState:
    def __init__(self, async_engine: AsyncLLMEngine, enable_sleep_mode: bool) -> None:
        from .vllm import create_engine_pause_and_resume_functions, patch_allocator

        if enable_sleep_mode:
            patch_allocator()
        self.async_engine = async_engine
        if enable_sleep_mode:
            self.pause_engine, self.resume_engine = (
                create_engine_pause_and_resume_functions(self.async_engine)
            )
        self.enable_sleep_mode = enable_sleep_mode
        self.driver_worker = cast(
            "WorkerWrapperBase",
            getattr(self.async_engine.engine.model_executor, "driver_worker"),
        )
        self.multi_step_model_runner: "MultiStepModelRunner" = (
            self.driver_worker.model_runner
        )

    @asynccontextmanager
    async def train_mode(self) -> AsyncGenerator[None, None]:
        """
        A context manager pauses the vLLM engine and frees memory for training.
        """
        if not self.enable_sleep_mode:
            yield
            return
        try:
            await self.pause_engine()
            try:
                if self.async_engine.engine.has_unfinished_requests():
                    # Offload KV cache to CPU memory (or disk)
                    await self.async_engine.sleep(level=1)
                else:
                    # Reset prefix cached and discard KV cache
                    await self.async_engine.reset_prefix_cache()
                    await self.async_engine.sleep(level=2)
                free_memory()
                yield
            finally:
                free_memory()
                await asyncio.sleep(0.1)
                await self.async_engine.wake_up()
        finally:
            await self.resume_engine()


def free_memory() -> None:
    for _ in range(3):
        gc.collect()
        torch.cuda.empty_cache()
