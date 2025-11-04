# 使用 NVIDIA CUDA 基础镜像（包含 CUDA 12.4）
# 明确指定 linux/amd64 平台以确保获取 x86_64 版本
FROM --platform=linux/amd64 nvidia/cuda:12.4.1-cudnn-devel-ubuntu22.04

# 设置环境变量
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    CUDA_HOME=/usr/local/cuda \
    PATH=/root/.local/bin:$PATH

# 安装系统依赖
RUN apt-get update && apt-get install -y \
    software-properties-common \
    && add-apt-repository ppa:deadsnakes/ppa -y \
    && apt-get update && apt-get install -y \
    python3.12 \
    python3.12-dev \
    python3.12-venv \
    git \
    wget \
    curl \
    build-essential \
    libssl-dev \
    libffi-dev \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# 安装 uv（快速的 Python 包管理器）
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# 设置工作目录
WORKDIR /workspace

# 复制项目文件
COPY . /workspace/

# 安装 Python 依赖
WORKDIR /workspace/examples/art-e

# 同步 art-e 的依赖（包含所有必需的包）
RUN uv sync

# 注意：uv sync 已经安装了所有依赖，包括：
# - torch, transformers, peft, trl, wandb, vllm 等
# - unsloth 会在运行时通过 uv 自动处理

# 设置 Python 路径
ENV PYTHONPATH=/workspace/src:$PYTHONPATH

# 设置默认命令
CMD ["uv", "run", "python", "art_e/train.py"]

