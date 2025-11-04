# Ollama + Qwen3 快速开始 ⚡

## 最快速度开始（3 步）

```bash
# 步骤 1: 运行自动设置
./scripts/setup_ollama.sh

# 步骤 2: 确认 Ollama 服务运行中
# (如果没有，运行: ollama serve)

# 步骤 3: 运行评估
python -m art_e.evaluate.benchmark_qwen3
```

完成！🎉

---

## 手动安装（如果自动脚本失败）

### 1️⃣ 安装 Ollama

**使用 Homebrew:**
```bash
brew install ollama
```

**或手动下载:**
https://ollama.ai/download/mac

### 2️⃣ 启动服务

```bash
ollama serve
```
保持这个终端运行！

### 3️⃣ 下载模型（新终端）

```bash
ollama pull qwen2.5:7b
```

### 4️⃣ 测试

```bash
ollama run qwen2.5:7b "你好"
```

### 5️⃣ 运行评估

```bash
cd /Users/zhenwei/workspace/ART/examples/art-e
python -m art_e.evaluate.benchmark_qwen3
```

---

## 验证安装

```bash
# 检查服务
curl http://localhost:11434/api/tags

# 列出模型
ollama list

# 诊断
./scripts/diagnose_environment.sh
```

---

## 常见问题

**Q: 如何停止 Ollama?**
A: 在运行 `ollama serve` 的终端按 `Ctrl+C`

**Q: 评估需要多长时间?**
A: 约 10-30 分钟（取决于模型大小和 limit 参数）

**Q: 如何更换模型?**
A: 编辑 `art_e/evaluate/benchmark_qwen3.py` 中的 `litellm_model_name`

**Q: 如何减少测试样本?**
A: 修改 `benchmark_qwen3.py` 中的 `limit=100` 改为 `limit=10`

---

## 推荐配置

| 内存 | 推荐模型 | 下载命令 |
|------|----------|----------|
| 8GB | qwen2.5:3b | `ollama pull qwen2.5:3b` |
| 16GB | qwen2.5:7b | `ollama pull qwen2.5:7b` ✓ |
| 32GB+ | qwen2.5:14b | `ollama pull qwen2.5:14b` |

---

## 需要帮助?

- 📖 完整指南: `OLLAMA_SETUP.md`
- 🔧 诊断工具: `./scripts/diagnose_environment.sh`
- 🌐 Ollama 文档: https://ollama.ai/docs

