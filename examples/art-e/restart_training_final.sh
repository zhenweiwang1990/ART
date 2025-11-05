#!/bin/bash
# 在服务器上执行的训练重启脚本
set -e

echo "=== Restarting Training ==="

# 1. 清理
pkill -9 -f "python" 2>/dev/null || true
sleep 3

# 2. 清理 GPU
nvidia-smi --query-compute-apps=pid --format=csv,noheader | xargs -r kill -9 2>/dev/null || true
sleep 1

#3. 清理缓存
cd /root/ART
find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true

# 4. 启动训练
cd /root/ART/examples/art-e
export PATH="/root/.local/bin:$PATH"
export RUN_ID="QWEN3_14B"
export IMPORT_UNSLOTH="0"

nohup /root/.local/bin/uv run python art_e/train.py > training.log 2>&1 &
TRAIN_PID=$!

echo "Training started (PID: $TRAIN_PID)"
echo ""
echo "Waiting 90 seconds for model to load..."
sleep 90

echo ""
echo "=== Training Log (last 80 lines) ==="
tail -80 training.log

echo ""
echo "=== GPU Status ==="
nvidia-smi --query-gpu=memory.used,utilization.gpu --format=csv

echo ""
if ps -p $TRAIN_PID > /dev/null 2>&1; then
    echo "✓ Training is running"
    echo ""
    echo "Monitor with: tail -f training.log"
    echo "Check WandB at: https://wandb.ai"
else
    echo "✗ Training exited - check log above for errors"
fi

