#!/bin/bash
# 诊断脚本：检查 Qwen3 部署环境
# 使用方法: ./scripts/diagnose_environment.sh

echo "======================================"
echo "环境诊断"
echo "======================================"
echo

# 检查操作系统
echo "1. 操作系统信息:"
uname -a
echo

# 检查 Python 版本
echo "2. Python 版本:"
python3 --version
echo

# 检查是否有 NVIDIA GPU
echo "3. GPU 检测:"
if command -v nvidia-smi &> /dev/null; then
    echo "✓ 检测到 NVIDIA GPU:"
    nvidia-smi --query-gpu=name,memory.total --format=csv
    echo "   → 推荐使用: vLLM"
elif system_profiler SPDisplaysDataType 2>/dev/null | grep -q "Metal"; then
    echo "⚠ 检测到 Apple Silicon (Metal)"
    echo "   → 推荐使用: Ollama (vLLM 不支持 macOS)"
else
    echo "✗ 未检测到 GPU"
    echo "   → 推荐使用: Ollama 或云 API"
fi
echo

# 检查 vLLM 是否已安装
echo "4. vLLM 安装状态:"
if python3 -c "import vllm" 2>/dev/null; then
    echo "✓ vLLM 已安装"
    python3 -c "import vllm; print(f'   版本: {vllm.__version__}')" 2>/dev/null || echo "   无法获取版本"
else
    echo "✗ vLLM 未安装"
    echo "   安装命令: pip install vllm"
fi
echo

# 检查 Ollama 是否已安装
echo "5. Ollama 安装状态:"
if command -v ollama &> /dev/null; then
    echo "✓ Ollama 已安装"
    ollama --version 2>/dev/null || echo "   无法获取版本"
    
    # 检查 Ollama 服务是否运行
    if curl -s http://localhost:11434/api/tags &>/dev/null; then
        echo "✓ Ollama 服务正在运行"
        echo "   已下载的模型:"
        curl -s http://localhost:11434/api/tags | python3 -c "import sys, json; models = json.load(sys.stdin).get('models', []); [print(f'     - {m[\"name\"]}') for m in models]" 2>/dev/null || echo "     (无法列出模型)"
    else
        echo "✗ Ollama 服务未运行"
        echo "   启动命令: ollama serve"
    fi
else
    echo "✗ Ollama 未安装"
    echo "   安装命令: curl -fsSL https://ollama.ai/install.sh | sh"
fi
echo

# 检查 litellm 是否已安装
echo "6. LiteLLM 安装状态:"
if python3 -c "import litellm" 2>/dev/null; then
    echo "✓ litellm 已安装"
else
    echo "✗ litellm 未安装 (项目需要)"
    echo "   安装命令: pip install litellm"
fi
echo

echo "======================================"
echo "推荐方案:"
echo "======================================"

if command -v nvidia-smi &> /dev/null; then
    echo "✓ 你有 NVIDIA GPU，推荐使用 vLLM"
    echo "  1. 确保 vLLM 已安装: pip install vllm"
    echo "  2. 启动服务: ./scripts/run_vllm_qwen3.sh"
    echo "  3. 在 benchmark_qwen3.py 中使用方案 1（vLLM）"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    echo "⚠ 你在 macOS 上，推荐使用 Ollama"
    echo "  1. 安装 Ollama: curl -fsSL https://ollama.ai/install.sh | sh"
    echo "  2. 下载模型: ollama pull qwen2.5:7b"
    echo "  3. 启动服务: ollama serve"
    echo "  4. 在 benchmark_qwen3.py 中使用方案 2（Ollama）已配置好"
else
    echo "ℹ 未检测到 GPU，推荐使用 Ollama 或云 API"
fi

echo

