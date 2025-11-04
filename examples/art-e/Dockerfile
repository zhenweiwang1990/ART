# 使用 NVIDIA CUDA 基础镜像（包含 CUDA 12.4）
FROM nvidia/cuda:12.4.1-cudnn-devel-ubuntu22.04

# 设置环境变量
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    CUDA_HOME=/usr/local/cuda \
    PATH=/root/.local/bin:$PATH

# 安装系统依赖
RUN apt-get update && apt-get install -y \
    python3.12 \
    python3.12-dev \
    python3-pip \
    git \
    wget \
    curl \
    build-essential \
    libssl-dev \
    libffi-dev \
    && rm -rf /var/lib/apt/lists/*

# 安装 uv（快速的 Python 包管理器）
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# 设置工作目录
WORKDIR /workspace

# 复制项目文件
COPY . /workspace/

# 安装 Python 依赖
WORKDIR /workspace/examples/art-e

# 同步 art-e 的依赖
RUN uv sync

# 安装额外的训练依赖
RUN uv pip install \
    torch==2.6.0 \
    transformers==4.51.1 \
    peft==0.17.1 \
    trl==0.24.0 \
    wandb==0.22.3 \
    openai==1.66.3 \
    awscli \
    polars \
    vllm==0.8.5 \
    setproctitle \
    seaborn \
    matplotlib \
    bitsandbytes==0.48.2 \
    typer \
    tblib \
    litellm

# 安装 unsloth（需要源码编译）
RUN uv pip install "unsloth[cu124-torch250] @ git+https://github.com/unslothai/unsloth.git" --no-build-isolation

# 设置 Python 路径
ENV PYTHONPATH=/workspace/src:$PYTHONPATH

# 设置默认命令
CMD ["uv", "run", "python", "art_e/train.py"]

