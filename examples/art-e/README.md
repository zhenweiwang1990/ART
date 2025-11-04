# Art•E(mail)

## Project Overview

You can find a full write-up of this project in [this post on the OpenPipe blog](https://openpipe.ai/blog/art-e-mail-agent).

This project trains models using reinforcement learning (RL) to search through email datasets and answer user queries. The goal is to create agents that could potentially integrate with email providers (like a Gmail plugin), allowing users to ask questions like "what time does my wife's flight arrive on Friday" or "what are the next steps I committed to for project X" and receive accurate answers based on email content.

## Features

- Email database creation and management with SQLite
- Advanced search capabilities (keywords, date ranges, sender/recipient filters)
- Email question-answering with reinforcement learning
- Comprehensive model evaluation framework
- Performance benchmarking against multiple models

## Dataset

This project uses the Enron Email Dataset, downloaded from Kaggle. The dataset is processed and stored in a SQLite database with full-text search capabilities.

To generate training data, the system:

1. Processes email inboxes of Enron employees
2. Generates synthetic questions about email content
3. Creates training/validation splits for model training

## Requirements

- Python 3.10+
- Key dependencies:
  - art (for reinforcement learning)
  - pandas, polars (data processing)
  - mailparser, kaggle (dataset handling)
  - sqlite3 (database)
  - litellm (inference)
  - datasets, tqdm (data management)
- API keys:
  - Kaggle (for dataset download)
  - Model providers for evaluation (OpenAI, etc.)
- S3 bucket to store logs and model checkpoints (set via `BACKUP_BUCKET` env var)

## Installation

### Option A: Docker (推荐 - 环境一致性)

使用 Docker 可以避免复杂的依赖配置，适合云端批量部署：

```bash
# 1. 构建镜像
./docker_build.sh

# 2. 推送到 Docker Hub (用于云端部署)
./docker_push_only.sh

# 3. 配置环境变量
cp env.template .env
# 编辑 .env 文件，填写 API keys

# 4. 本地运行测试
./docker_run.sh

# 或使用 make 命令
make build
make push
make run
```

📖 **详细文档**: 
- **Docker 构建**: 见上述命令
- **RunPod 云端训练**: `RUNPOD_QUICKSTART.md` ⭐ (推荐)

### Option B: 直接安装（适合本地开发）

```bash
# Clone repository
git clone https://github.com/OpenPipe/ART
cd ART/examples/art-e

# Install package with uv (recommended - creates .venv automatically)
uv sync

# Activate the virtual environment
source .venv/bin/activate  # On Windows: .venv\Scripts\activate

# Or if you don't have uv, use pip:
# python3 -m venv venv
# source venv/bin/activate
# pip install -e .

# Create .env file with required variables
# BACKUP_BUCKET=your-s3-bucket-name
# OPENPIPE_API_KEY=your-key  # Optional, for logging
```

## Usage

### Creating the Synthetic Dataset

The following commands were used to create the initial dataset. However, you can skip this if you just want to reproduce the results, since the processed dataset is freely hosted at https://huggingface.co/datasets/corbt/enron_emails_sample_questions.

```bash
# Download and process the Enron dataset (default: 100 emails)
python -m art_e.data.convert_enron_email_dataset

# Process more emails
python -m art_e.data.convert_enron_email_dataset --max-emails 10000

# Optional: Upload to HuggingFace (requires HF_TOKEN environment variable)
python -m art_e.data.convert_enron_email_dataset --upload

# Generate SQLite database
python -c "from art_e.data.local_email_db import generate_database; generate_database(overwrite=True)"
```

### Training Models

#### 🚀 使用 Docker 在 RunPod 上训练（推荐）⭐

最简单的方式是使用已构建好的 Docker 镜像在 RunPod 上训练：

**快速启动 (5 分钟)**:

1. 访问 [RunPod Console](https://www.runpod.io/console/pods)
2. 点击 "+ Deploy"，选择 A100-80GB GPU
3. 配置 Docker 镜像: `YOUR_USERNAME/art-e-training:latest`
4. 添加环境变量（AWS credentials, WANDB_API_KEY 等）
5. 启动 Pod 并运行: `./start_runpod_training.sh`

📖 **详细指南**:
- **快速开始**: `RUNPOD_QUICKSTART.md` ⭐
- **完整文档**: `RUNPOD_TRAINING_GUIDE.md`
- **SkyPilot 配置**: `sky_runpod_docker.yaml`

**成本**: A100-80GB ~$2/小时，训练约 10-15 小时，总成本 $20-30

---

#### 使用 SkyPilot (原始方法)

I used `skypilot` with the [Runpod](https://www.runpod.io/) backend to train these models. Once you've authenticated Runpod for use with skypilot, the following command should start a training job that replicates our reported results:

```bash
uv run run_training_job.py 008 --fast
```

You can see the other model variants I tried training in `train.py`.

### Evaluating Models

#### Evaluating Cloud Models (GPT-4o, Claude, etc.)

```python
# Benchmark a model
from art_e.evaluate.benchmark import benchmark_model
from art_e.project_types import ProjectPolicyConfig
import asyncio
import art

# Create model
model = art.Model(
    name="gpt-4o",  # Can also use your trained models
    project="email_agent",
    config=ProjectPolicyConfig(
        litellm_model_name="openai/gpt-4o",
        use_tools=True,
    ),
)

# Run benchmark
results = asyncio.run(benchmark_model(model))
print(results)
```

#### Evaluating Qwen3 Models

**⚠️ 注意**: Email Agent 需要工具调用支持。推荐使用云 API。

**方法 1: DashScope API（阿里云 - 推荐）⭐**

```bash
# 1. 获取 API Key: https://dashscope.console.aliyun.com/apiKey
export DASHSCOPE_API_KEY=your_key

# 2. 运行评估
python -m art_e.evaluate.benchmark_qwen3_dashscope
```

**方法 2: OpenAI API（如果有 GPT-4 access）**

```bash
export OPENAI_API_KEY=your_key
python -m art_e.evaluate.benchmark_openai
```

**方法 3: vLLM 本地部署（Linux + NVIDIA GPU）**

```bash
# 1. 启动 vLLM 服务器
./scripts/run_vllm_qwen3.sh

# 2. 运行评估
python -m art_e.evaluate.benchmark_qwen3
```

**方法 4: Ollama（macOS - 工具调用有问题）**
- ⚠️ 当前 Ollama 的工具调用与 litellm 不兼容
- 参见 [TOOL_CALLING_SOLUTIONS.md](TOOL_CALLING_SOLUTIONS.md) 了解详情和替代方案

详细文档:
- 🔧 [TOOL_CALLING_SOLUTIONS.md](TOOL_CALLING_SOLUTIONS.md) - 工具调用问题和解决方案
- 📚 [EVALUATE_QWEN3.md](EVALUATE_QWEN3.md) - 完整评估指南
- 🦙 [OLLAMA_SETUP.md](OLLAMA_SETUP.md) - Ollama 设置（工具调用暂不可用）

## Project Structure

- **data/**: Dataset processing and management

  - `convert_enron_email_dataset.py`: Downloads/processes Enron dataset
  - `local_email_db.py`: SQLite database creation and management
  - `generate_synthetic_question_data.py`: Creates question-answer pairs
  - `query_iterators.py`: Loads datasets for training/evaluation
  - `types_enron.py`: Data models for emails and queries

- **email_search_tools.py**: Tools for searching and retrieving emails

- **evaluate/**: Model evaluation

  - `benchmark.py`: Performance benchmarking
  - `evaluate.py`: Analysis and visualization tools

- **train.py**: Main training script

- **rollout.py**: Defines model-environment interaction

- **project_types.py**: Configuration classes

## How It Works

1. **Data Preparation**: Process Enron emails into a searchable database
2. **Question Generation**: Create synthetic questions about emails
3. **Training**: Models learn via reinforcement learning to:
   - Search for relevant emails using keywords
   - Read email content to extract information
   - Formulate correct answers with proper citations
4. **Rewards**: System provides rewards based on answer correctness, sourcing, and efficiency
5. **Evaluation**: Compare models on metrics like accuracy, turn count, and source citation

## Performance Metrics

The evaluation framework tracks:

- Answer correctness (semantic match to ground truth)
- Source citation accuracy (identifying the correct email)
- Efficiency (number of turns to find answer)
- Tool use effectiveness
- Search strategy quality

Models are benchmarked against commercial LLMs like GPT-4.1 and Gemini 2.5 Pro to measure relative performance.
