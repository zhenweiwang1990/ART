#!/bin/bash
# 完全手动运行训练 - 绕过 SkyPilot

set -e

# 从 .env 加载环境变量
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

RUN_ID=${1:-002}
HOST=${2:-38.128.232.9}
PORT=${3:-35769}

echo "🔧 手动运行训练"
echo ""
echo "配置:"
echo "  RUN_ID: ${RUN_ID}"
echo "  主机: ${HOST}:${PORT}"
echo ""

# 检查必要的环境变量
if [ -z "$BACKUP_BUCKET" ] || [ -z "$AWS_ACCESS_KEY_ID" ]; then
    echo "❌ 错误: .env 文件配置不完整"
    exit 1
fi

# SSH 密钥
KEY=~/.ssh/sky-key

echo "1️⃣ 测试连接..."
if ! ssh -i $KEY root@$HOST -p $PORT -o StrictHostKeyChecking=no -o ConnectTimeout=5 "echo '连接成功'" 2>/dev/null; then
    echo "❌ 无法连接到实例"
    exit 1
fi
echo "✅ SSH 连接正常"
echo ""

echo "2️⃣ 上传代码和配置..."
# 打包当前目录
cd /Users/zhenwei/workspace/ART
tar czf /tmp/art-code.tar.gz \
    --exclude='.git' \
    --exclude='*.pyc' \
    --exclude='__pycache__' \
    --exclude='.venv' \
    --exclude='venv' \
    --exclude='*.db' \
    examples/art-e src

# 上传
scp -i $KEY -P $PORT -o StrictHostKeyChecking=no \
    /tmp/art-code.tar.gz \
    root@$HOST:/root/
echo "✅ 代码已上传"
echo ""

echo "3️⃣ 在远程服务器上设置环境..."
ssh -i $KEY root@$HOST -p $PORT -o StrictHostKeyChecking=no << SETUP
set -e

# 解压代码
cd /root
tar xzf art-code.tar.gz
cd examples/art-e

# 设置环境变量
cat > .env << 'ENVEOF'
BACKUP_BUCKET=${BACKUP_BUCKET}
AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
AWS_REGION=${AWS_REGION:-us-east-1}
WANDB_API_KEY=${WANDB_API_KEY}
OPENAI_API_KEY=${OPENAI_API_KEY}
OPENPIPE_API_KEY=${OPENPIPE_API_KEY:-}
RUN_ID=${RUN_ID}
HF_HUB_ENABLE_HF_TRANSFER=1
ENVEOF

echo "✅ 环境变量已设置"

# 安装 uv
if ! command -v uv &> /dev/null; then
    echo "安装 uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="\$HOME/.local/bin:\$PATH"
fi

# 设置 Python 环境
echo "设置 Python 环境..."
cd /root/examples/art-e
uv remove openpipe-art 2>/dev/null || true
uv add --editable /root/src 2>/dev/null || true
uv add awscli
uv sync

echo "✅ 环境设置完成"
SETUP

echo ""
echo "4️⃣ 启动训练..."
echo "训练将在后台运行，日志保存到远程服务器"
echo ""

# 启动训练（使用 nohup 在后台运行）
ssh -i $KEY root@$HOST -p $PORT -o StrictHostKeyChecking=no << 'TRAIN'
set -e
cd /root/examples/art-e

# 使用 nohup 在后台运行训练
export PATH="$HOME/.local/bin:$PATH"
nohup bash -c '
    cd /root/examples/art-e
    export PATH="$HOME/.local/bin:$PATH"
    source .env
    echo "$(date): 开始训练" >> training.log
    uv run python art_e/train.py 2>&1 | tee -a training.log
    echo "$(date): 训练完成" >> training.log
' > /root/nohup.out 2>&1 &

echo "训练进程 PID: $!"
sleep 2

# 检查进程是否还在运行
if ps -p $! > /dev/null 2>&1; then
    echo "✅ 训练已在后台启动"
else
    echo "⚠️ 训练进程可能已退出，检查日志"
fi

echo ""
echo "查看训练进度:"
echo "  tail -f /root/examples/art-e/training.log"
echo "  # 或查看 nohup 输出:"
echo "  tail -f /root/nohup.out"
TRAIN

echo ""
echo "🎉 训练已启动！"
echo ""
echo "监控命令:"
echo "  # 查看实时训练日志"
echo "  ssh -i $KEY root@$HOST -p $PORT 'tail -f /root/examples/art-e/training.log'"
echo ""
echo "  # 查看 nohup 输出"
echo "  ssh -i $KEY root@$HOST -p $PORT 'tail -f /root/nohup.out'"
echo ""
echo "  # 查看 GPU 使用"
echo "  ssh -i $KEY root@$HOST -p $PORT 'nvidia-smi'"
echo ""
echo "  # 检查训练进程"
echo "  ssh -i $KEY root@$HOST -p $PORT 'ps aux | grep python'"
echo ""
echo "  # SSH 进入服务器"
echo "  ssh -i $KEY root@$HOST -p $PORT"
echo ""
