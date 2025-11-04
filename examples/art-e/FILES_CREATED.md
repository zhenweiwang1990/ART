# 为 Qwen3 评估创建的文件

本文档列出了为评估 Qwen3 模型而创建的所有文件。

## 📁 新建文件列表

### 1. 核心评估脚本
- **`art_e/evaluate/benchmark_qwen3.py`**
  - 主要的 Qwen3 评估脚本
  - 配置为连接本地 vLLM 服务器
  - 使用方法: `python -m art_e.evaluate.benchmark_qwen3`

### 2. 部署脚本
- **`scripts/run_vllm_qwen3.sh`** ✓ (可执行)
  - vLLM 服务器启动脚本
  - 包含多种配置选项的注释
  - 使用方法: `./scripts/run_vllm_qwen3.sh`

### 3. 测试工具
- **`scripts/test_vllm_server.py`** ✓ (可执行)
  - 测试 vLLM 服务器连接和功能
  - 验证模型是否正常工作
  - 使用方法: `python scripts/test_vllm_server.py`

### 4. 文档
- **`QUICKSTART_QWEN3.md`**
  - 快速启动指南（3 步开始评估）
  - 包含常见问题和故障排除
  - 推荐首先阅读

- **`EVALUATE_QWEN3.md`**
  - 完整的评估指南
  - 涵盖 3 种部署方案：vLLM、Ollama、云 API
  - 包含性能优化和多 GPU 配置
  - 适合深度使用

- **`FILES_CREATED.md`** (本文件)
  - 文件清单和说明

### 5. 更新的文件
- **`README.md`** (已更新)
  - 添加了 Qwen3 评估部分
  - 链接到详细文档

## 🚀 快速开始

最简单的方式是按照以下顺序：

1. **阅读**: `QUICKSTART_QWEN3.md`
2. **启动服务器**: `./scripts/run_vllm_qwen3.sh` 或手动启动
3. **测试连接** (可选): `python scripts/test_vllm_server.py`
4. **运行评估**: `python -m art_e.evaluate.benchmark_qwen3`

## 📚 文件依赖关系

```
QUICKSTART_QWEN3.md  (快速指南)
    ↓
scripts/run_vllm_qwen3.sh  (启动 vLLM)
    ↓
scripts/test_vllm_server.py  (测试连接)
    ↓
art_e/evaluate/benchmark_qwen3.py  (运行评估)
    ↓
art_e/evaluate/benchmark.py  (核心评估逻辑)
```

详细配置和高级选项请参考 `EVALUATE_QWEN3.md`。

## 🔍 文件内容概览

### benchmark_qwen3.py
```python
# 配置本地 Qwen3 模型连接
model = art.Model(
    name="qwen3-local",
    project="email_agent",
    config=ProjectPolicyConfig(
        litellm_model_name="openai/Qwen2.5-72B-Instruct",
        use_tools=True,
        max_turns=30,
    ),
)

# 运行评估
results = await benchmark_model(model, limit=100)
```

### run_vllm_qwen3.sh
```bash
# 启动 vLLM OpenAI 兼容服务器
python -m vllm.entrypoints.openai.api_server \
    --model Qwen/Qwen2.5-72B-Instruct \
    --host 0.0.0.0 \
    --port 8000 \
    --gpu-memory-utilization 0.9 \
    --trust-remote-code
```

### test_vllm_server.py
```python
# 测试服务器连接、文本生成和工具调用
def test_vllm_server(base_url="http://localhost:8000"):
    # 1. 检查服务器状态
    # 2. 测试文本生成
    # 3. 测试工具调用（可选）
```

## 🎯 使用场景

| 场景 | 推荐文件 |
|------|----------|
| 第一次使用 | `QUICKSTART_QWEN3.md` |
| 需要详细配置 | `EVALUATE_QWEN3.md` |
| 快速测试连接 | `scripts/test_vllm_server.py` |
| 自动化部署 | `scripts/run_vllm_qwen3.sh` |
| 运行评估 | `art_e/evaluate/benchmark_qwen3.py` |
| 对比多个模型 | `EVALUATE_QWEN3.md` (性能对比部分) |

## 📝 自定义修改

如需修改评估参数，编辑以下文件：

- **测试样本数量**: `benchmark_qwen3.py` 中的 `limit` 参数
- **模型配置**: `benchmark_qwen3.py` 中的 `ProjectPolicyConfig`
- **服务器参数**: `run_vllm_qwen3.sh` 中的 vLLM 参数
- **模型选择**: 两个文件中的模型名称

## ✅ 检查清单

评估 Qwen3 前的准备：

- [ ] 阅读 `QUICKSTART_QWEN3.md`
- [ ] 确认有足够的 GPU 显存
- [ ] 安装 vLLM: `pip install vllm`
- [ ] 启动 vLLM 服务器
- [ ] 测试连接正常
- [ ] 运行评估脚本
- [ ] 查看和分析结果

## 🆘 获取帮助

- 快速问题: 查看 `QUICKSTART_QWEN3.md` 的故障排除部分
- 详细配置: 查看 `EVALUATE_QWEN3.md`
- vLLM 问题: 访问 [vLLM 文档](https://docs.vllm.ai/)
- 模型问题: 访问 [Qwen 官方文档](https://github.com/QwenLM/Qwen)

