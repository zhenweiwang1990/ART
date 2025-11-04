# 评估 Qwen3 模型指南

本指南介绍如何在本地部署 Qwen3 模型并在 email agent 任务上评估其性能。

## 方案一：使用 vLLM 本地部署（推荐）

### 优点
- 高性能推理
- OpenAI 兼容 API
- 支持批量处理
- 易于集成

### 步骤

#### 1. 安装依赖

```bash
# 安装 vLLM（需要 CUDA）
pip install vllm

# 或使用 uv
uv pip install vllm
```

#### 2. 启动 vLLM 服务器

使用提供的脚本：

```bash
./scripts/run_vllm_qwen3.sh
```

或手动启动：

```bash
# 使用 72B 模型（需要约 140GB+ GPU 显存）
python -m vllm.entrypoints.openai.api_server \
    --model Qwen/Qwen2.5-72B-Instruct \
    --host 0.0.0.0 \
    --port 8000 \
    --gpu-memory-utilization 0.9 \
    --dtype auto \
    --trust-remote-code

# 或使用 14B 模型（需要约 28GB GPU 显存）
python -m vllm.entrypoints.openai.api_server \
    --model Qwen/Qwen2.5-14B-Instruct \
    --host 0.0.0.0 \
    --port 8000 \
    --gpu-memory-utilization 0.9 \
    --dtype auto \
    --trust-remote-code
```

**多 GPU 使用：**
```bash
# 使用 2 张 GPU 进行张量并行
python -m vllm.entrypoints.openai.api_server \
    --model Qwen/Qwen2.5-72B-Instruct \
    --tensor-parallel-size 2 \
    --host 0.0.0.0 \
    --port 8000
```

**使用量化模型（需要更少显存）：**
```bash
# 使用 AWQ 量化版本
python -m vllm.entrypoints.openai.api_server \
    --model Qwen/Qwen2.5-72B-Instruct-AWQ \
    --quantization awq \
    --host 0.0.0.0 \
    --port 8000
```

#### 3. 验证服务器运行

```bash
# 测试服务器是否正常运行
curl http://localhost:8000/v1/models
```

#### 4. 运行评估

```bash
# 确保在虚拟环境中
source .venv/bin/activate

# 运行评估脚本
python -m art_e.evaluate.benchmark_qwen3
```

或在 Python 中：

```python
import asyncio
from art_e.evaluate.benchmark_qwen3 import main

results = asyncio.run(main())
```

---

## 方案二：使用云 API（不需要本地 GPU）

如果你没有足够的 GPU 资源，可以使用 Qwen 的云 API 服务。

### 使用阿里云 DashScope

```python
import art
from art_e.evaluate.benchmark import benchmark_model
from art_e.project_types import ProjectPolicyConfig
import asyncio
import os

# 设置 API Key
os.environ["DASHSCOPE_API_KEY"] = "your-api-key"

model = art.Model(
    name="qwen3-dashscope",
    project="email_agent",
    config=ProjectPolicyConfig(
        litellm_model_name="dashscope/qwen-plus",  # 或 qwen-turbo, qwen-max
        use_tools=True,
        max_turns=30,
    ),
)

results = asyncio.run(benchmark_model(model, limit=100))
print(results)
```

### 使用 Together.ai 或其他提供商

```python
import os

os.environ["TOGETHER_API_KEY"] = "your-api-key"

model = art.Model(
    name="qwen3-together",
    project="email_agent",
    config=ProjectPolicyConfig(
        litellm_model_name="together_ai/Qwen/Qwen2.5-72B-Instruct",
        use_tools=True,
        max_turns=30,
    ),
)

results = asyncio.run(benchmark_model(model, limit=100))
```

---

## 方案三：使用 Ollama（最简单的本地部署）

Ollama 提供了最简单的本地模型部署方式。

### 1. 安装 Ollama

```bash
# macOS/Linux
curl -fsSL https://ollama.ai/install.sh | sh

# 或访问 https://ollama.ai 下载
```

### 2. 拉取 Qwen 模型

```bash
# 拉取 Qwen2.5 72B（需要约 40GB 磁盘空间）
ollama pull qwen2.5:72b

# 或拉取更小的版本
ollama pull qwen2.5:14b
ollama pull qwen2.5:7b
```

### 3. 启动服务

```bash
# Ollama 会自动在后台运行，默认端口 11434
ollama serve
```

### 4. 评估脚本

```python
import art
from art_e.evaluate.benchmark import benchmark_model
from art_e.project_types import ProjectPolicyConfig
import asyncio
import os

os.environ["OLLAMA_API_BASE"] = "http://localhost:11434"

model = art.Model(
    name="qwen3-ollama",
    project="email_agent",
    config=ProjectPolicyConfig(
        litellm_model_name="ollama/qwen2.5:72b",
        use_tools=True,
        max_turns=30,
    ),
)

results = asyncio.run(benchmark_model(model, limit=100))
print(results)
```

---

## 性能对比建议

为了完整评估，建议同时测试不同规模的模型：

```python
import asyncio
from art_e.evaluate.benchmark import benchmark_model
from art_e.project_types import ProjectPolicyConfig
import art

async def compare_models():
    models = [
        ("qwen3-72b", "openai/Qwen2.5-72B-Instruct"),
        ("qwen3-14b", "openai/Qwen2.5-14B-Instruct"),
        ("gpt-4o", "openai/gpt-4o"),  # 作为基准
    ]
    
    results = {}
    for name, model_name in models:
        print(f"\n{'='*50}")
        print(f"评估: {name}")
        print(f"{'='*50}")
        
        model = art.Model(
            name=name,
            project="email_agent",
            config=ProjectPolicyConfig(
                litellm_model_name=model_name,
                use_tools=True,
                max_turns=30,
            ),
        )
        
        result = await benchmark_model(model, limit=100)
        results[name] = result
        print(result)
    
    return results

# 运行对比
results = asyncio.run(compare_models())
```

---

## 常见问题

### Q: vLLM 启动失败，提示显存不足
A: 尝试：
- 使用更小的模型（14B 而不是 72B）
- 降低 `--gpu-memory-utilization` (如 0.8)
- 减小 `--max-model-len` (如 2048)
- 使用量化模型（AWQ/GPTQ）

### Q: 评估速度很慢
A: 
- 增加 `--gpu-memory-utilization`
- 调整 vLLM 的批处理参数 `--max-num-batched-tokens`
- 使用多 GPU 张量并行

### Q: 如何查看详细的评估结果
A: 评估结果会包含多个指标。你可以查看 `art_e/evaluate/` 目录下的其他工具来进行更详细的分析。

---

## 评估指标说明

benchmark 会返回以下指标的平均值：

- `reward`: 总体奖励分数
- 其他任务相关的自定义指标（在 `rollout.py` 中定义）
- `n_trajectories`: 成功完成的测试样本数量

详细的指标定义请参考 `rollout.py` 中的奖励函数。

