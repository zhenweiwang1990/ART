#!/bin/bash
# 强制启动训练 - 使用最宽松的超时设置

set -e

RUN_ID=${1:-002}
GPU=${2:-A100-80GB:1}

echo "🚀 强制启动训练 (RUN_ID=${RUN_ID}, GPU=${GPU})"
echo ""

# 1. 清理
echo "1. 清理之前的集群..."
uv run sky down kyle-email-agent-${RUN_ID} --purge -y 2>/dev/null || true
sleep 2

# 2. 设置最宽松的配置
echo "2. 优化 SkyPilot 配置..."
cat > ~/.sky/config.yaml << 'SKYEOF'
# 最宽松的超时配置
ssh:
  connect_timeout: 60  # 60 秒超时
  
# 大幅增加重试
max_cluster_status_retries: 120

# 禁用一些检查以加快连接
jobs:
  controller:
    resources:
      disk_size: 50
SKYEOF

# 3. 添加环境变量以增加详细日志
export SKYPILOT_DEBUG=1

# 4. 启动
echo ""
echo "3. 启动训练任务..."
echo "   GPU: ${GPU}"
echo "   配置: agent_${RUN_ID}"
echo ""

uv run run_training_job.py ${RUN_ID} \
    --fast \
    --accelerator "${GPU}" \
    --idle-minutes 120

echo ""
if [ $? -eq 0 ]; then
    echo "✅ 启动成功！"
else
    echo "❌ 启动失败"
    echo ""
    echo "备选方案：手动运行"
    echo "运行: ./manual_training.sh"
fi
