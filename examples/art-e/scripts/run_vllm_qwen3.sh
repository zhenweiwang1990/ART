#!/bin/bash
# 本地部署 Qwen3 模型使用 vLLM
# 使用方法: ./scripts/run_vllm_qwen3.sh

# 禁用 PyTorch 分布式初始化（避免 TCPStore 警告）
export VLLM_WORKER_MULTIPROC_METHOD=spawn
export VLLM_CONFIGURE_LOGGING=0

# 设置模型路径 - 可以是 HuggingFace 模型名称或本地路径
MODEL_NAME="Qwen/Qwen3-4B-Instruct-2507-FP8"  # 或者改为 Qwen/Qwen2.5-14B-Instruct 如果显存不够

# 启动 vLLM OpenAI 兼容服务器
# 调整 --gpu-memory-utilization 和 --max-model-len 根据你的 GPU 显存
python -m vllm.entrypoints.openai.api_server \
    --model $MODEL_NAME \
    --host 0.0.0.0 \
    --port 8000 \
    --gpu-memory-utilization 0.9 \
    --max-model-len 4096 \
    --dtype auto \
    --trust-remote-code

# 其他有用的参数：
# --tensor-parallel-size 2   # 如果有多张 GPU
# --quantization awq         # 如果使用量化模型
# --served-model-name qwen3  # 自定义模型名称

