#!/bin/bash
# 快速手动在 RunPod 上启动 Docker 训练
# 当 SkyPilot SSH 连接慢时使用

set -e

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

# 从日志中提取 SSH 信息
SSH_HOST="69.30.85.62"
SSH_PORT="22097"
SSH_KEY="~/.ssh/sky-key"

echo -e "${BLUE}🚀 直接连接到 RunPod 并启动训练${NC}"
echo ""
echo "SSH: root@${SSH_HOST}:${SSH_PORT}"
echo ""

# 替换为你的 Docker Hub 用户名
DOCKER_IMAGE="YOUR_USERNAME/art-e-training:latest"

echo -e "${YELLOW}请输入你的 Docker Hub 用户名:${NC}"
read -p "Docker Hub 用户名: " DOCKER_USERNAME

if [ -z "$DOCKER_USERNAME" ]; then
    echo -e "${RED}❌ 用户名不能为空${NC}"
    exit 1
fi

DOCKER_IMAGE="${DOCKER_USERNAME}/art-e-training:latest"

echo ""
echo -e "${BLUE}📦 Docker 镜像: ${DOCKER_IMAGE}${NC}"
echo ""
echo -e "${YELLOW}正在连接并设置环境...${NC}"

# 执行远程命令
ssh -i ~/.ssh/sky-key root@${SSH_HOST} -p ${SSH_PORT} -o StrictHostKeyChecking=no << EOF
set -e

echo "=========================================="
echo "🐳 拉取 Docker 镜像"
echo "=========================================="
docker pull ${DOCKER_IMAGE}

echo ""
echo "=========================================="
echo "📂 创建目录"
echo "=========================================="
mkdir -p ~/checkpoints ~/output ~/wandb ~/logs

echo ""
echo "=========================================="
echo "🔑 配置环境变量"
echo "=========================================="
# 这里需要你手动填写环境变量
cat > ~/.env << 'ENVEOF'
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key
WANDB_API_KEY=your_wandb_key
IMPORT_UNSLOTH=0
ENVEOF

echo "⚠️  请编辑 ~/.env 文件填写真实的 API keys"

echo ""
echo "=========================================="
echo "🚀 启动训练"
echo "=========================================="

# 后台运行训练
nohup docker run --rm --gpus all \
  --env-file ~/.env \
  -v ~/checkpoints:/workspace/examples/art-e/checkpoints \
  -v ~/output:/workspace/examples/art-e/output \
  -v ~/wandb:/workspace/examples/art-e/wandb \
  --shm-size 64gb \
  --name art-e-training \
  ${DOCKER_IMAGE} \
  uv run python art_e/train.py > ~/logs/training.log 2>&1 &

echo \$! > ~/training.pid

echo ""
echo "✅ 训练已在后台启动！"
echo "进程 ID: \$(cat ~/training.pid)"
echo ""
echo "查看日志: tail -f ~/logs/training.log"
echo "停止训练: kill \$(cat ~/training.pid)"
EOF

echo ""
echo -e "${GREEN}✅ 设置完成！${NC}"
echo ""
echo -e "${YELLOW}接下来的步骤:${NC}"
echo "1. SSH 连接到服务器:"
echo "   ssh -i ~/.ssh/sky-key root@${SSH_HOST} -p ${SSH_PORT}"
echo ""
echo "2. 编辑环境变量:"
echo "   vim ~/.env"
echo ""
echo "3. 启动训练（如果还没启动）:"
echo "   docker run --rm --gpus all --env-file ~/.env -v ~/checkpoints:/workspace/examples/art-e/checkpoints --shm-size 64gb ${DOCKER_IMAGE} uv run python art_e/train.py"
echo ""
echo "4. 查看日志:"
echo "   tail -f ~/logs/training.log"
echo ""
echo -e "${GREEN}🎉 完成！${NC}"

