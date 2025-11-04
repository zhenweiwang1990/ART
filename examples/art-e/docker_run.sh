#!/bin/bash
set -e

# Docker 容器运行脚本

IMAGE_NAME="art-e-training:latest"
CONTAINER_NAME="art-e-train-$(date +%Y%m%d-%H%M%S)"

echo "🚀 启动 ART-E 训练容器..."

# 检查 .env 文件
if [ ! -f ".env" ]; then
    echo "⚠️  警告: .env 文件不存在"
    echo "请从 .env.template 复制并配置环境变量"
    read -p "是否继续（不使用 .env）? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
    ENV_FILE_ARG=""
else
    ENV_FILE_ARG="--env-file .env"
fi

# 检查 GPU 可用性
if ! docker run --rm --gpus all nvidia/cuda:12.4.1-base-ubuntu22.04 nvidia-smi > /dev/null 2>&1; then
    echo "❌ 错误: GPU 不可用或 NVIDIA Docker 运行时未安装"
    echo "请确保:"
    echo "  1. 已安装 NVIDIA 驱动"
    echo "  2. 已安装 nvidia-docker2"
    echo "  3. Docker 配置了 GPU 支持"
    exit 1
fi

echo "✅ GPU 检测通过"
echo ""

# 创建必要的目录（如果不存在）
mkdir -p data
mkdir -p outputs
mkdir -p checkpoints

# 运行容器
echo "启动容器: ${CONTAINER_NAME}"
docker run \
    --name ${CONTAINER_NAME} \
    --gpus all \
    ${ENV_FILE_ARG} \
    -v $(pwd)/data:/workspace/examples/art-e/data \
    -v $(pwd)/outputs:/workspace/examples/art-e/outputs \
    -v $(pwd)/checkpoints:/workspace/examples/art-e/checkpoints \
    --shm-size=16g \
    --ipc=host \
    --rm \
    -it \
    ${IMAGE_NAME} \
    "$@"

echo ""
echo "✅ 训练完成或容器已退出"

