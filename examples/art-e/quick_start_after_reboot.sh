#!/bin/bash
# 在 RunPod 实例重启后运行此脚本来快速开始训练
set -e

echo "=== Quick Start Training After Reboot ==="
echo ""

# 1. 环境设置
export PATH="/root/.local/bin:$PATH"
export CUDA_VISIBLE_DEVICES="0"
export RUN_ID="QWEN3_14B"
export IMPORT_UNSLOTH="1"  # 重启后尝试启用 Unsloth

cd /root/ART/examples/art-e

# 2. 验证环境
echo "Checking CUDA..."
python3 -c "import torch; print(f'CUDA: {torch.cuda.is_available()}, Devices: {torch.cuda.device_count()}')"

echo ""
echo "Checking GPU..."
nvidia-smi --query-gpu=name,memory.total,driver_version --format=csv

# 3. 测试 Unsloth（如果失败就禁用）
echo ""
echo "Testing Unsloth..."
if /root/.local/bin/uv run python -c "import os; os.environ['IMPORT_UNSLOTH']='1'; import unsloth; print('Unsloth OK')" 2>&1 | grep -q "Unsloth OK"; then
    echo "✓ Unsloth works - using it for training"
    export IMPORT_UNSLOTH="1"
else
    echo "⚠️  Unsloth not working - falling back to standard transformers"
    export IMPORT_UNSLOTH="0"
fi

# 4. 启动训练
echo ""
echo "Starting training..."
echo "  Model: Qwen2.5-14B-Instruct"
echo "  Unsloth: $([ "$IMPORT_UNSLOTH" = "1" ] && echo 'Enabled' || echo 'Disabled')"
echo "  WandB: Enabled"
echo ""

nohup /root/.local/bin/uv run python art_e/train.py > training.log 2>&1 &
TRAIN_PID=$!
echo "Training started (PID: $TRAIN_PID)"

# 5. 等待并检查
echo ""
echo "Waiting 120 seconds for model to load..."
sleep 120

echo ""
echo "=== Initial Training Log ==="
tail -80 training.log

echo ""
echo "=== GPU Status ==="
nvidia-smi --query-gpu=memory.used,utilization.gpu --format=csv

echo ""
echo "=== WandB Check ==="
if grep -qi "wandb.*tracking\|wandb.*logged in" training.log; then
    echo "✓✓✓ WandB IS WORKING! ✓✓✓"
    echo ""
    echo "🎉 Training started successfully!"
    echo "📊 Monitor at: https://wandb.ai"
elif grep -q "Traceback\|Error" training.log; then
    echo "✗ Error detected - check log above"
else
    echo "⏳ Still initializing..."
fi

echo ""
echo "Monitor logs: tail -f /root/ART/examples/art-e/training.log"

