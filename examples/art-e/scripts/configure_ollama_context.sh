#!/bin/bash
# 为 Qwen3 配置更大的上下文窗口
# 使用方法: ./scripts/configure_ollama_context.sh

set -e

echo "======================================"
echo "配置 Qwen3 上下文窗口"
echo "======================================"
echo

MODEL_NAME="qwen3-32k"
BASE_MODEL="qwen3:8b"

echo "创建自定义模型: $MODEL_NAME"
echo "基础模型: $BASE_MODEL"
echo "上下文窗口: 32768 tokens (32k)"
echo

# 使用 Modelfile 创建自定义模型
cd "$(dirname "$0")/.."

if [ ! -f "Modelfile.qwen3" ]; then
    echo "错误: Modelfile.qwen3 不存在"
    exit 1
fi

echo "正在创建模型..."
ollama create $MODEL_NAME -f Modelfile.qwen3

if [ $? -eq 0 ]; then
    echo
    echo "✓ 模型创建成功！"
    echo
    echo "======================================"
    echo "下一步"
    echo "======================================"
    echo "1. 测试模型:"
    echo "   ollama run $MODEL_NAME"
    echo
    echo "2. 更新评估脚本使用新模型:"
    echo "   编辑 art_e/evaluate/benchmark_qwen3.py"
    echo "   将 'ollama/qwen3:8b' 改为 'ollama/$MODEL_NAME'"
    echo
    echo "3. 运行评估:"
    echo "   python -m art_e.evaluate.benchmark_qwen3"
    echo
    
    echo "已安装的模型:"
    ollama list
else
    echo "✗ 模型创建失败"
    exit 1
fi

