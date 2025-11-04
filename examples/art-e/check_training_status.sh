#!/bin/bash
# 检查训练状态脚本

echo "🔍 检查 SkyPilot 集群状态..."
echo ""

# 激活虚拟环境
if [ -f .venv/bin/activate ]; then
    source .venv/bin/activate
fi

# 检查状态
echo "1️⃣ 集群状态:"
uv run sky status kyle-email-agent-002 2>/dev/null || echo "  (集群不存在或未启动)"
echo ""

# 检查任务队列
echo "2️⃣ 任务队列:"
uv run sky queue kyle-email-agent-002 2>/dev/null || echo "  (无法查看队列，可能集群未完全启动)"
echo ""

echo "💡 提示:"
echo "  - 如果状态是 INIT: 等待 5-10 分钟，正在初始化"
echo "  - 如果状态是 UP: 可以查看日志了"
echo "  - 查看日志命令: uv run sky logs kyle-email-agent-002 --follow"
echo ""
