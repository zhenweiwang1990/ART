#!/bin/bash
set -e

# 云端 Docker 容器运行脚本
# 适用于 RunPod、Lambda Labs、Vast.ai 等云 GPU 平台

IMAGE_NAME="art-e-training:latest"
CONTAINER_NAME="art-e-training"

echo "☁️  在云端启动 ART-E 训练容器..."

# 检查 .env 文件
if [ ! -f ".env" ]; then
    echo "❌ 错误: .env 文件不存在"
    echo "请创建 .env 文件并配置以下环境变量:"
    echo "  - AWS_ACCESS_KEY_ID"
    echo "  - AWS_SECRET_ACCESS_KEY"
    echo "  - BACKUP_BUCKET"
    echo "  - WANDB_API_KEY"
    echo "  - OPENAI_API_KEY"
    echo "  - KAGGLE_USERNAME (可选)"
    echo "  - KAGGLE_KEY (可选)"
    echo "  - RUN_ID (可选)"
    exit 1
fi

echo "✅ 找到 .env 文件"

# 创建必要的目录
mkdir -p data outputs checkpoints

# 在后台运行容器并保存日志
echo "🚀 启动训练容器（后台模式）..."
docker run \
    --name ${CONTAINER_NAME} \
    --gpus all \
    --env-file .env \
    -v $(pwd)/data:/workspace/examples/art-e/data \
    -v $(pwd)/outputs:/workspace/examples/art-e/outputs \
    -v $(pwd)/checkpoints:/workspace/examples/art-e/checkpoints \
    --shm-size=16g \
    --ipc=host \
    --restart=unless-stopped \
    -d \
    ${IMAGE_NAME}

echo ""
echo "✅ 容器已启动！"
echo ""
echo "📊 监控命令:"
echo "  查看日志:    docker logs -f ${CONTAINER_NAME}"
echo "  查看状态:    docker ps | grep ${CONTAINER_NAME}"
echo "  进入容器:    docker exec -it ${CONTAINER_NAME} bash"
echo "  停止训练:    docker stop ${CONTAINER_NAME}"
echo "  查看 GPU:    nvidia-smi"
echo ""
echo "📝 训练日志:"
docker logs ${CONTAINER_NAME}

