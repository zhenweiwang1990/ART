#!/bin/bash
# 云端训练环境设置脚本

echo "🔧 设置云端训练环境..."

# 激活虚拟环境
source .venv/bin/activate

# 验证 sky 命令
if command -v sky &> /dev/null; then
    echo "✅ SkyPilot CLI 已就绪"
    sky --version
else
    echo "❌ SkyPilot 未安装"
    exit 1
fi

echo ""
echo "环境已激活！现在可以运行："
echo "  sky check runpod"
echo "  ./quick_start_training.sh 002 A10G:1"
echo ""
echo "或直接使用 uv (推荐):"
echo "  uv run run_training_job.py 002 --fast --accelerator A10G:1"
