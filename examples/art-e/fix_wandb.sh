#!/bin/bash
# 在远程训练服务器上运行此脚本以修复 WandB 配置

set -e

echo "=== WandB Configuration Diagnostic ==="
echo ""

# 1. 检查 .env 文件
echo "1. Checking .env file..."
if [ -f /root/ART/examples/art-e/.env ]; then
    echo "✓ .env file exists"
    if grep -q "WANDB_API_KEY" /root/ART/examples/art-e/.env; then
        echo "✓ WANDB_API_KEY found in .env"
        # 显示前几个字符确认
        key=$(grep "WANDB_API_KEY" /root/ART/examples/art-e/.env | cut -d'=' -f2 | head -c 20)
        echo "  Key starts with: ${key}..."
    else
        echo "✗ WANDB_API_KEY NOT found in .env"
        echo ""
        echo "Please add your WandB API key:"
        echo "  1. Get your key from: https://wandb.ai/authorize"
        echo "  2. Add to .env file:"
        echo "     echo 'WANDB_API_KEY=your_key_here' >> /root/ART/examples/art-e/.env"
        exit 1
    fi
else
    echo "✗ .env file NOT found"
    echo ""
    echo "Creating .env file from template..."
    if [ -f /root/ART/examples/art-e/env.template ]; then
        cp /root/ART/examples/art-e/env.template /root/ART/examples/art-e/.env
        echo "✓ Created .env from template"
        echo ""
        echo "Please add your WandB API key:"
        echo "  1. Get your key from: https://wandb.ai/authorize"
        echo "  2. Edit .env file:"
        echo "     nano /root/ART/examples/art-e/.env"
        echo "  3. Add line: WANDB_API_KEY=your_key_here"
        exit 1
    else
        echo "Creating new .env file..."
        touch /root/ART/examples/art-e/.env
        echo "Please add your WandB API key:"
        echo "  echo 'WANDB_API_KEY=your_key_here' >> /root/ART/examples/art-e/.env"
        exit 1
    fi
fi

echo ""

# 2. 检查当前环境变量
echo "2. Checking environment variable..."
if [ -n "$WANDB_API_KEY" ]; then
    key_preview=$(echo "$WANDB_API_KEY" | head -c 20)
    echo "✓ WANDB_API_KEY is set in environment: ${key_preview}..."
else
    echo "✗ WANDB_API_KEY NOT set in current shell"
    echo "  Loading from .env..."
    source /root/ART/examples/art-e/.env
    if [ -n "$WANDB_API_KEY" ]; then
        echo "✓ Successfully loaded from .env"
    else
        echo "✗ Failed to load from .env"
        exit 1
    fi
fi

echo ""

# 3. 检查 WandB 安装
echo "3. Checking wandb installation..."
cd /root/ART/examples/art-e
if uv run python -c "import wandb; print(f'wandb version: {wandb.__version__}')" 2>/dev/null; then
    echo "✓ wandb is installed"
else
    echo "✗ wandb import failed"
    echo "  Installing wandb..."
    uv pip install wandb
fi

echo ""

# 4. 测试 WandB 登录
echo "4. Testing WandB authentication..."
cd /root/ART/examples/art-e
export WANDB_API_KEY=$(grep "WANDB_API_KEY" /root/ART/examples/art-e/.env | cut -d'=' -f2 | tr -d ' "' | tr -d "'")
if uv run python -c "import wandb; import os; wandb.login(key=os.environ.get('WANDB_API_KEY')); print('✓ WandB authentication successful')" 2>/dev/null; then
    echo "✓ WandB authentication works"
else
    echo "✗ WandB authentication failed"
    echo "  Please check your API key is valid"
    exit 1
fi

echo ""
echo "=== WandB Configuration OK ==="
echo ""
echo "To start training with WandB enabled:"
echo ""
echo "  cd /root/ART/examples/art-e"
echo "  export \$(grep -v '^#' .env | xargs)"
echo "  export RUN_ID=QWEN3_14B"
echo "  uv run python art_e/train.py"
echo ""

