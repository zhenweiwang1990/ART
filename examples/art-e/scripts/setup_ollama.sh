#!/bin/bash
# Ollama 快速设置脚本（macOS）
# 使用方法: ./scripts/setup_ollama.sh

set -e

echo "======================================"
echo "Ollama 设置向导"
echo "======================================"
echo

# 检查是否已安装
if command -v ollama &> /dev/null; then
    echo "✓ Ollama 已安装"
    ollama --version
    echo
else
    echo "✗ Ollama 未安装"
    echo
    echo "请选择安装方法:"
    echo "  1. 使用 Homebrew (推荐)"
    echo "  2. 手动下载"
    echo
    read -p "选择 [1/2]: " choice
    
    case $choice in
        1)
            if ! command -v brew &> /dev/null; then
                echo "错误: Homebrew 未安装"
                echo "请先安装 Homebrew: https://brew.sh"
                exit 1
            fi
            echo "正在使用 Homebrew 安装 Ollama..."
            brew install ollama
            ;;
        2)
            echo "请访问以下链接手动下载:"
            echo "  https://ollama.ai/download/mac"
            echo
            echo "下载并安装后，重新运行此脚本。"
            exit 0
            ;;
        *)
            echo "无效选择"
            exit 1
            ;;
    esac
    echo
fi

# 检查服务是否运行
echo "检查 Ollama 服务状态..."
if curl -s http://localhost:11434/api/tags &>/dev/null; then
    echo "✓ Ollama 服务正在运行"
else
    echo "✗ Ollama 服务未运行"
    echo
    echo "启动 Ollama 服务..."
    echo "（这将在后台运行 Ollama）"
    
    # 在 macOS 上使用后台启动
    nohup ollama serve > /tmp/ollama.log 2>&1 &
    OLLAMA_PID=$!
    
    echo "等待服务启动..."
    for i in {1..10}; do
        if curl -s http://localhost:11434/api/tags &>/dev/null; then
            echo "✓ Ollama 服务已启动 (PID: $OLLAMA_PID)"
            break
        fi
        sleep 1
    done
    
    if ! curl -s http://localhost:11434/api/tags &>/dev/null; then
        echo "✗ 服务启动失败"
        echo "请手动运行: ollama serve"
        exit 1
    fi
fi

echo

# 列出已安装的模型
echo "检查已安装的 Qwen 模型..."
INSTALLED_MODELS=$(curl -s http://localhost:11434/api/tags | python3 -c "import sys, json; models = json.load(sys.stdin).get('models', []); qwen = [m['name'] for m in models if 'qwen' in m['name'].lower()]; print(','.join(qwen))" 2>/dev/null)

if [ -n "$INSTALLED_MODELS" ]; then
    echo "✓ 已安装的 Qwen 模型:"
    echo "$INSTALLED_MODELS" | tr ',' '\n' | sed 's/^/  - /'
    echo
    echo "是否需要下载其他模型? [y/N]"
    read -p "> " download_more
    if [[ ! "$download_more" =~ ^[Yy]$ ]]; then
        echo
        echo "======================================"
        echo "设置完成！"
        echo "======================================"
        echo "运行评估: python -m art_e.evaluate.benchmark_qwen3"
        exit 0
    fi
else
    echo "✗ 未找到 Qwen 模型"
fi

echo
echo "======================================"
echo "下载 Qwen 模型"
echo "======================================"
echo
echo "推荐模型:"
echo "  1. qwen2.5:7b  - 推荐（约 4.7GB）"
echo "  2. qwen2.5:14b - 更好性能（约 9GB）"
echo "  3. qwen2.5:3b  - 轻量级（约 2GB）"
echo "  4. 自定义"
echo
read -p "选择 [1-4]: " model_choice

case $model_choice in
    1) MODEL="qwen2.5:7b" ;;
    2) MODEL="qwen2.5:14b" ;;
    3) MODEL="qwen2.5:3b" ;;
    4)
        read -p "输入模型名称 (如 qwen2.5:7b): " MODEL
        ;;
    *)
        echo "无效选择，使用默认: qwen2.5:7b"
        MODEL="qwen2.5:7b"
        ;;
esac

echo
echo "正在下载 $MODEL..."
echo "（这可能需要几分钟，取决于网络速度）"
ollama pull $MODEL

echo
echo "======================================"
echo "测试模型"
echo "======================================"
echo "发送测试请求..."
TEST_RESPONSE=$(ollama run $MODEL "用一句话介绍你自己" 2>&1)
if [ $? -eq 0 ]; then
    echo "✓ 模型工作正常"
    echo "回复: $TEST_RESPONSE"
else
    echo "✗ 模型测试失败"
    echo "$TEST_RESPONSE"
fi

echo
echo "======================================"
echo "设置完成！"
echo "======================================"
echo
echo "已安装的模型:"
ollama list
echo
echo "下一步:"
echo "  1. 运行评估: python -m art_e.evaluate.benchmark_qwen3"
echo "  2. 或查看完整指南: cat OLLAMA_SETUP.md"
echo
echo "有用的命令:"
echo "  - 列出模型: ollama list"
echo "  - 交互测试: ollama run $MODEL"
echo "  - 查看日志: tail -f /tmp/ollama.log"
echo

