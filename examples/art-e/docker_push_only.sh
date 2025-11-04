#!/bin/bash
set -e

# 仅推送已构建的镜像到 Docker Hub

IMAGE_NAME="art-e-training"
IMAGE_TAG="latest"
FULL_IMAGE_NAME="${IMAGE_NAME}:${IMAGE_TAG}"

echo "📤 推送 Docker 镜像到 Docker Hub"
echo "================================"
echo ""

# 检查镜像是否存在
if ! docker images | grep -q "^${IMAGE_NAME}"; then
    echo "❌ 错误: 本地找不到镜像 ${FULL_IMAGE_NAME}"
    echo ""
    echo "请先构建镜像:"
    echo "  ./docker_build.sh"
    echo ""
    exit 1
fi

echo "✅ 找到本地镜像: ${FULL_IMAGE_NAME}"
echo ""

# 获取镜像信息
docker images | grep "^${IMAGE_NAME}" | head -1
echo ""

# 获取 Docker Hub 用户名
if [ -z "$DOCKERHUB_USERNAME" ]; then
    read -p "请输入你的 Docker Hub 用户名: " DOCKERHUB_USERNAME
fi

if [ -z "$DOCKERHUB_USERNAME" ]; then
    echo "❌ 错误: Docker Hub 用户名不能为空"
    exit 1
fi

REMOTE_IMAGE="${DOCKERHUB_USERNAME}/${FULL_IMAGE_NAME}"

echo "🏷️  远程镜像名: ${REMOTE_IMAGE}"
echo ""

# 标记镜像
echo "🏷️  标记镜像..."
docker tag ${FULL_IMAGE_NAME} ${REMOTE_IMAGE}
echo "✅ 完成"
echo ""

# 登录 Docker Hub
echo "🔐 登录 Docker Hub..."
docker login

if [ $? -ne 0 ]; then
    echo "❌ 登录失败！"
    exit 1
fi
echo ""

# 推送镜像
echo "📤 推送镜像..."
echo "⏱️  这可能需要 10-20 分钟（取决于网速）"
echo ""

docker push ${REMOTE_IMAGE}

if [ $? -ne 0 ]; then
    echo ""
    echo "❌ 推送失败！"
    exit 1
fi

echo ""
echo "================================"
echo "🎉 推送成功！"
echo "================================"
echo ""
echo "🌐 Docker Hub 地址:"
echo "   https://hub.docker.com/r/${DOCKERHUB_USERNAME}/${IMAGE_NAME}"
echo ""
echo "💡 在其他机器上使用:"
echo ""
echo "   # 拉取镜像"
echo "   docker pull ${REMOTE_IMAGE}"
echo ""
echo "   # 重命名为本地名称"
echo "   docker tag ${REMOTE_IMAGE} ${FULL_IMAGE_NAME}"
echo ""
echo "   # 运行训练"
echo "   ./docker_run_cloud.sh"
echo ""

