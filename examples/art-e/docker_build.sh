#!/bin/bash
set -e

# Docker 镜像构建脚本

echo "🐳 开始构建 ART-E 训练 Docker 镜像..."

# 镜像名称和标签
IMAGE_NAME="art-e-training"
IMAGE_TAG="latest"
FULL_IMAGE_NAME="${IMAGE_NAME}:${IMAGE_TAG}"

# 检查是否在正确的目录
if [ ! -f "Dockerfile" ]; then
    echo "❌ 错误: 在当前目录找不到 Dockerfile"
    echo "请确保在 examples/art-e 目录下运行此脚本"
    exit 1
fi

# 切换到项目根目录（因为需要复制整个项目）
cd ../..
PROJECT_ROOT=$(pwd)

echo "📁 项目根目录: $PROJECT_ROOT"

# 构建 Docker 镜像
echo "🔨 构建镜像 ${FULL_IMAGE_NAME}..."
docker build \
    -f examples/art-e/Dockerfile \
    -t ${FULL_IMAGE_NAME} \
    --build-arg BUILDKIT_INLINE_CACHE=1 \
    .

echo ""
echo "✅ Docker 镜像构建完成！"
echo ""
echo "镜像信息:"
docker images | grep ${IMAGE_NAME} | head -1

echo ""
echo "📝 下一步:"
echo "1. 配置 .env 文件（复制 .env.template 并填写）"
echo "2. 运行训练: ./docker_run.sh"
echo "3. 或推送到镜像仓库: docker push ${FULL_IMAGE_NAME}"

