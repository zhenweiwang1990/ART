#!/bin/bash
# 在 RunPod Pod 内使用此脚本启动训练
# 用法: ./start_runpod_training.sh

set -e

BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}🚀 ART-E 训练启动脚本 (RunPod)${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 检查 GPU
echo -e "${BLUE}🔍 检查 GPU...${NC}"
if ! nvidia-smi &> /dev/null; then
    echo -e "${RED}❌ 错误: 未检测到 GPU${NC}"
    exit 1
fi

nvidia-smi --query-gpu=name,memory.total --format=csv,noheader
echo ""

# 检查当前目录
echo -e "${BLUE}📁 当前工作目录: $(pwd)${NC}"
EXPECTED_DIR="/workspace/examples/art-e"
if [ "$(pwd)" != "$EXPECTED_DIR" ]; then
    echo -e "${YELLOW}⚠️  当前不在预期目录，正在切换...${NC}"
    cd "$EXPECTED_DIR"
fi
echo ""

# 检查环境变量
echo -e "${BLUE}🔑 检查环境变量...${NC}"
REQUIRED_VARS=("AWS_ACCESS_KEY_ID" "AWS_SECRET_ACCESS_KEY" "WANDB_API_KEY")
MISSING_VARS=()

for VAR in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!VAR}" ]; then
        MISSING_VARS+=("$VAR")
        echo -e "${RED}  ❌ $VAR 未设置${NC}"
    else
        echo -e "${GREEN}  ✅ $VAR 已设置${NC}"
    fi
done

if [ ${#MISSING_VARS[@]} -gt 0 ]; then
    echo ""
    echo -e "${RED}❌ 缺少必需的环境变量！${NC}"
    echo -e "${YELLOW}请在 RunPod Pod 配置中设置这些环境变量，或创建 .env 文件${NC}"
    exit 1
fi
echo ""

# 创建必要的目录
echo -e "${BLUE}📂 创建目录...${NC}"
mkdir -p checkpoints output wandb logs
echo -e "${GREEN}✅ 目录已创建${NC}"
echo ""

# 设置日志文件
LOG_FILE="logs/training_$(date +%Y%m%d_%H%M%S).log"
echo -e "${BLUE}📝 日志文件: ${LOG_FILE}${NC}"
echo ""

# 询问运行模式
echo -e "${YELLOW}选择运行模式:${NC}"
echo "1) 前台运行（实时查看输出）"
echo "2) 后台运行（推荐，可以断开连接）"
echo ""
read -p "$(echo -e "${BLUE}请选择 [1/2, 默认: 2]: ${NC}")" RUN_MODE
RUN_MODE=${RUN_MODE:-2}

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}🎯 开始训练${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

if [ "$RUN_MODE" == "1" ]; then
    # 前台运行
    echo -e "${GREEN}▶️  前台运行模式${NC}"
    echo -e "${YELLOW}提示: 按 Ctrl+C 停止训练${NC}"
    echo ""
    sleep 2
    
    uv run python art_e/train.py 2>&1 | tee "$LOG_FILE"
    
else
    # 后台运行
    echo -e "${GREEN}▶️  后台运行模式${NC}"
    echo ""
    
    # 启动训练
    nohup uv run python art_e/train.py > "$LOG_FILE" 2>&1 &
    TRAIN_PID=$!
    
    # 保存 PID
    echo $TRAIN_PID > training.pid
    
    echo -e "${GREEN}✅ 训练已在后台启动！${NC}"
    echo ""
    echo -e "${BLUE}训练信息:${NC}"
    echo "  进程 ID: $TRAIN_PID"
    echo "  日志文件: $LOG_FILE"
    echo ""
    echo -e "${BLUE}监控命令:${NC}"
    echo "  查看实时日志: tail -f $LOG_FILE"
    echo "  查看 GPU 使用: watch -n 1 nvidia-smi"
    echo "  查看进程: ps aux | grep train.py"
    echo ""
    echo -e "${BLUE}停止训练:${NC}"
    echo "  kill $TRAIN_PID"
    echo "  或: kill \$(cat training.pid)"
    echo ""
    echo -e "${YELLOW}🔗 Weights & Biases:${NC}"
    echo "  https://wandb.ai/\${WANDB_ENTITY}/\${WANDB_PROJECT}"
    echo ""
    
    # 等待几秒，检查是否正常启动
    sleep 5
    if ps -p $TRAIN_PID > /dev/null; then
        echo -e "${GREEN}✅ 训练正在运行中...${NC}"
        echo ""
        echo -e "${BLUE}最新日志:${NC}"
        tail -20 "$LOG_FILE"
    else
        echo -e "${RED}❌ 训练进程意外退出${NC}"
        echo ""
        echo -e "${YELLOW}查看日志:${NC}"
        tail -50 "$LOG_FILE"
        exit 1
    fi
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}🎉 脚本执行完成${NC}"
echo -e "${BLUE}========================================${NC}"

