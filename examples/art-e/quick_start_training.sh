#!/bin/bash
# 快速启动云端训练脚本
# 使用方法: ./quick_start_training.sh [配置ID] [GPU类型]
# 示例: ./quick_start_training.sh 002 A10G

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 ART Email Agent 云端训练启动脚本${NC}\n"

# 激活虚拟环境（如果存在）
if [ -f .venv/bin/activate ]; then
    echo -e "${BLUE}激活虚拟环境...${NC}"
    source .venv/bin/activate
fi

# 检查参数
RUN_ID=${1:-002}
ACCELERATOR=${2:-A10G:1}

echo -e "${GREEN}配置信息:${NC}"
echo "  - 训练配置: agent_${RUN_ID}"
echo "  - GPU 类型: ${ACCELERATOR}"
echo ""

# 检查 .env 文件
if [ ! -f .env ]; then
    echo -e "${RED}❌ 错误: .env 文件不存在${NC}"
    echo ""
    echo "请先创建 .env 文件:"
    echo "  1. cp .env.template .env"
    echo "  2. 编辑 .env 填入你的 API keys"
    echo ""
    echo "详细步骤请查看: CLOUD_TRAINING_SETUP.md"
    exit 1
fi

# 加载环境变量
export $(cat .env | grep -v '^#' | xargs)

# 检查必需的环境变量
missing_vars=()

if [ -z "$BACKUP_BUCKET" ]; then
    missing_vars+=("BACKUP_BUCKET")
fi

if [ -z "$AWS_ACCESS_KEY_ID" ]; then
    missing_vars+=("AWS_ACCESS_KEY_ID")
fi

if [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
    missing_vars+=("AWS_SECRET_ACCESS_KEY")
fi

if [ -z "$OPENAI_API_KEY" ]; then
    missing_vars+=("OPENAI_API_KEY")
fi

if [ ${#missing_vars[@]} -ne 0 ]; then
    echo -e "${RED}❌ 错误: 缺少必需的环境变量${NC}"
    echo ""
    for var in "${missing_vars[@]}"; do
        echo "  - $var"
    done
    echo ""
    echo "请在 .env 文件中配置这些变量"
    exit 1
fi

# 检查 SkyPilot
echo -e "${BLUE}检查 SkyPilot...${NC}"
if ! command -v sky &> /dev/null; then
    echo -e "${RED}❌ SkyPilot 未安装${NC}"
    echo "安装: uv pip install 'skypilot[runpod]'"
    exit 1
fi
echo -e "${GREEN}✅ SkyPilot 已安装${NC}"

# 检查云提供商配置
echo -e "\n${BLUE}检查云提供商配置...${NC}"
if sky check runpod 2>&1 | grep -q "enabled"; then
    echo -e "${GREEN}✅ RunPod 已配置${NC}"
else
    echo -e "${YELLOW}⚠️  RunPod 未配置，请运行: sky check runpod${NC}"
    read -p "是否继续? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# 检查 S3 访问
echo -e "\n${BLUE}检查 S3 访问...${NC}"
if aws s3 ls s3://$BACKUP_BUCKET &> /dev/null; then
    echo -e "${GREEN}✅ S3 存储桶可访问${NC}"
else
    echo -e "${RED}❌ 无法访问 S3 存储桶: $BACKUP_BUCKET${NC}"
    echo "请检查 AWS 凭证和存储桶名称"
    exit 1
fi

# GPU 成本估算
case "$ACCELERATOR" in
    *A10G*)
        COST="$0.50/hr (预计 $5-10 完整训练)"
        ;;
    *A100-40GB*)
        COST="$1.50/hr (预计 $15-30 完整训练)"
        ;;
    *A100-80GB*|*A100:1*)
        COST="$2.50/hr (预计 $25-50 完整训练)"
        ;;
    *H100*)
        COST="$3.50/hr (预计 $35-70 完整训练)"
        ;;
    *)
        COST="未知"
        ;;
esac

echo -e "\n${BLUE}成本估算:${NC}"
echo "  GPU: ${ACCELERATOR}"
echo "  价格: ${COST}"
echo "  其他: ~$2-3 (S3 + OpenAI API)"
echo ""

# 确认启动
echo -e "${YELLOW}⚠️  即将启动云端训练，将产生费用${NC}"
read -p "确认启动? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "已取消"
    exit 0
fi

# 启动训练
echo -e "\n${GREEN}🚀 启动训练...${NC}\n"

uv run run_training_job.py ${RUN_ID} \
    --fast \
    --accelerator "${ACCELERATOR}" \
    --idle-minutes 60

echo -e "\n${GREEN}✅ 训练任务已提交${NC}"
echo ""
echo "监控训练:"
echo "  - 查看日志: sky logs kyle-email-agent-${RUN_ID} --follow"
echo "  - W&B Dashboard: https://wandb.ai/"
echo "  - 查看状态: sky status"
echo ""
echo "管理任务:"
echo "  - 停止训练: sky down kyle-email-agent-${RUN_ID}"
echo "  - 取消任务: sky cancel kyle-email-agent-${RUN_ID}"
echo ""


