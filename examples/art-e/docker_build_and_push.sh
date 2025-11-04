#!/bin/bash
set -e

# Docker 镜像构建并推送到 Docker Hub 的完整脚本

echo "🐳 ART-E Docker 镜像 - 构建并推送"
echo "=================================="
echo ""

# 镜像配置
IMAGE_NAME="art-e-training"
IMAGE_TAG="latest"
FULL_IMAGE_NAME="${IMAGE_NAME}:${IMAGE_TAG}"

# 获取 Docker Hub 用户名
if [ -z "$DOCKERHUB_USERNAME" ]; then
    read -p "请输入你的 Docker Hub 用户名: " DOCKERHUB_USERNAME
fi

if [ -z "$DOCKERHUB_USERNAME" ]; then
    echo "❌ 错误: Docker Hub 用户名不能为空"
    exit 1
fi

REMOTE_IMAGE="${DOCKERHUB_USERNAME}/${FULL_IMAGE_NAME}"

echo "📝 配置信息:"
echo "  本地镜像: ${FULL_IMAGE_NAME}"
echo "  远程镜像: ${REMOTE_IMAGE}"
echo ""

# 步骤 1: 构建镜像
echo "=============================="
echo "步骤 1/3: 构建 Docker 镜像"
echo "=============================="
echo ""
echo "⏱️  预计时间: 20-30 分钟"
echo "💾 预计大小: 15-20 GB"
echo ""

read -p "是否继续构建？(y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ 取消构建"
    exit 1
fi

# 检查是否在正确的目录
if [ ! -f "Dockerfile" ]; then
    echo "❌ 错误: 在当前目录找不到 Dockerfile"
    exit 1
fi

# 切换到项目根目录
cd ../..
PROJECT_ROOT=$(pwd)

echo "📁 项目根目录: $PROJECT_ROOT"
echo "🔨 开始构建..."
echo ""

# 构建镜像
docker build \
    -f examples/art-e/Dockerfile \
    -t ${FULL_IMAGE_NAME} \
    --build-arg BUILDKIT_INLINE_CACHE=1 \
    .

if [ $? -ne 0 ]; then
    echo ""
    echo "❌ 构建失败！"
    exit 1
fi

echo ""
echo "✅ 构建完成！"
echo ""

# 步骤 2: 标记镜像
echo "=============================="
echo "步骤 2/3: 标记镜像"
echo "=============================="
echo ""

docker tag ${FULL_IMAGE_NAME} ${REMOTE_IMAGE}

echo "✅ 镜像已标记为: ${REMOTE_IMAGE}"
echo ""

# 步骤 3: 登录并推送
echo "=============================="
echo "步骤 3/3: 推送到 Docker Hub"
echo "=============================="
echo ""

# 检查是否已登录
if ! docker info 2>/dev/null | grep -q "Username"; then
    echo "📝 需要登录 Docker Hub..."
    docker login
    
    if [ $? -ne 0 ]; then
        echo "❌ 登录失败！"
        exit 1
    fi
    echo ""
fi

echo "📤 开始推送镜像到 Docker Hub..."
echo "⏱️  预计时间: 10-20 分钟（取决于网速）"
echo ""

docker push ${REMOTE_IMAGE}

if [ $? -ne 0 ]; then
    echo ""
    echo "❌ 推送失败！"
    exit 1
fi

echo ""
echo "=============================="
echo "🎉 完成！"
echo "=============================="
echo ""
echo "✅ 镜像已成功推送到 Docker Hub"
echo ""
echo "📦 镜像信息:"
docker images | grep ${IMAGE_NAME} | head -2
echo ""
echo "🌐 Docker Hub 地址:"
echo "   https://hub.docker.com/r/${DOCKERHUB_USERNAME}/${IMAGE_NAME}"
echo ""
echo "💡 在其他机器上使用:"
echo "   docker pull ${REMOTE_IMAGE}"
echo "   docker tag ${REMOTE_IMAGE} ${FULL_IMAGE_NAME}"
echo "   ./docker_run_cloud.sh"
echo ""
echo "📝 或者使用 SkyPilot:"
echo "   修改 sky_docker.yaml 中的镜像名为: ${REMOTE_IMAGE}"
echo "   sky launch -c art-e-docker sky_docker.yaml"
echo ""

