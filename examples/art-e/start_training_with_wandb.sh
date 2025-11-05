#!/bin/bash
# 在远程训练服务器上运行此脚本以启动带 WandB 的训练

set -e

echo "=== Starting Training with WandB ==="
echo ""

# 切换到项目目录
cd /root/ART/examples/art-e

# 1. 检查并加载 .env
if [ ! -f .env ]; then
    echo "Error: .env file not found"
    echo "Please run fix_wandb.sh first"
    exit 1
fi

echo "Loading environment variables from .env..."
export $(grep -v '^#' .env | xargs)

# 2. 验证 WANDB_API_KEY
if [ -z "$WANDB_API_KEY" ]; then
    echo "Error: WANDB_API_KEY not set"
    echo "Please run fix_wandb.sh first"
    exit 1
fi

echo "✓ WANDB_API_KEY loaded"

# 3. 设置训练配置
if [ -z "$RUN_ID" ]; then
    export RUN_ID="QWEN3_14B"
    echo "Using default RUN_ID: $RUN_ID"
else
    echo "Using RUN_ID: $RUN_ID"
fi

# 4. 可选：设置其他环境变量
# export IMPORT_UNSLOTH=1  # 如果想启用 Unsloth 优化
# export BACKUP_BUCKET="your-s3-bucket"  # 如果想启用 S3 备份

echo ""
echo "Starting training..."
echo "  Project: email_agent"
echo "  Model: email-agent-qwen3-14b"
echo "  WandB: enabled"
echo ""
echo "Monitor at: https://wandb.ai"
echo ""
echo "Press Ctrl+C to stop training"
echo ""

# 5. 启动训练
uv run python art_e/train.py

