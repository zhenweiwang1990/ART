#!/bin/bash
# 重新启动训练脚本

set -e

echo "🔧 清理并重新启动训练..."
echo ""

# 颜色
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

RUN_ID=${1:-002}
GPU_TYPE=${2:-A10G:1}

echo -e "${BLUE}1. 清理之前的集群...${NC}"
uv run sky down kyle-email-agent-${RUN_ID} --purge -y 2>/dev/null || echo "  (没有需要清理的集群)"
sleep 2
echo ""

echo -e "${BLUE}2. 检查可用的 GPU...${NC}"
echo "查询 ${GPU_TYPE%:*} 的可用性..."
uv run sky show-gpus --gpus ${GPU_TYPE%:*} --cloud runpod || true
echo ""

echo -e "${YELLOW}3. 准备启动训练...${NC}"
echo "  配置: agent_${RUN_ID}"
echo "  GPU: ${GPU_TYPE}"
echo ""

read -p "继续启动? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "已取消"
    exit 0
fi

echo -e "${GREEN}4. 启动训练任务...${NC}"
echo ""

uv run run_training_job.py ${RUN_ID} --fast --accelerator "${GPU_TYPE}"

echo ""
echo -e "${GREEN}✅ 启动命令已执行${NC}"
echo "如果再次失败，尝试其他 GPU 类型："
echo "  - ./restart_training.sh ${RUN_ID} A100-40GB:1"
echo "  - ./restart_training.sh ${RUN_ID} A6000:1"
