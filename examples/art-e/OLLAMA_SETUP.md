# Ollama 设置指南（macOS）

## 快速开始

### 步骤 1: 安装 Ollama

**方法 1: 使用 Homebrew（推荐）**
```bash
brew install ollama
```

**方法 2: 手动下载**
访问 https://ollama.ai/download/mac 下载并安装

### 步骤 2: 启动 Ollama 服务

在一个终端窗口中运行：
```bash
ollama serve
```

保持这个窗口开着。你应该看到类似：
```
Listening on 127.0.0.1:11434 (version 0.x.x)
```

### 步骤 3: 下载 Qwen 模型

打开**另一个**终端窗口，运行：

```bash
# 下载 7B 模型（推荐，约 4.7GB）
ollama pull qwen2.5:7b

# 或者下载更大的模型
# ollama pull qwen2.5:14b   # 约 9GB
# ollama pull qwen2.5:32b   # 约 20GB
```

### 步骤 4: 测试模型

```bash
# 简单测试
ollama run qwen2.5:7b "你好，介绍一下你自己"

# 或者交互式对话
ollama run qwen2.5:7b
```

输入 `/bye` 退出交互模式。

### 步骤 5: 运行评估

确保 Ollama 服务在后台运行，然后：

```bash
cd /Users/zhenwei/workspace/ART/examples/art-e

# 激活虚拟环境（如果有）
source .venv/bin/activate

# 运行评估
python -m art_e.evaluate.benchmark_qwen3
```

## 验证安装

运行诊断脚本检查一切是否正常：

```bash
./scripts/diagnose_environment.sh
```

## Ollama 常用命令

```bash
# 列出已下载的模型
ollama list

# 删除模型
ollama rm qwen2.5:7b

# 查看模型信息
ollama show qwen2.5:7b

# 停止服务（在运行 ollama serve 的终端按 Ctrl+C）
```

## 可用的 Qwen 模型

| 模型 | 大小 | 推荐场景 |
|------|------|----------|
| `qwen2.5:0.5b` | ~400MB | 快速测试 |
| `qwen2.5:1.5b` | ~1GB | 轻量级任务 |
| `qwen2.5:3b` | ~2GB | 平衡性能 |
| `qwen2.5:7b` | ~4.7GB | **推荐** - 性能与速度平衡 |
| `qwen2.5:14b` | ~9GB | 更好性能 |
| `qwen2.5:32b` | ~20GB | 最佳性能（需要更多内存）|
| `qwen2.5:72b` | ~48GB | 顶级性能（需要大量内存）|

## 故障排除

### 问题: "connection refused"
**解决**: 确保 `ollama serve` 正在运行

### 问题: 模型下载很慢
**解决**: 使用国内镜像（如果可用）或等待下载完成

### 问题: 内存不足
**解决**: 使用更小的模型（如 3b 或 7b）

### 问题: 评估脚本无法连接
**检查**:
```bash
# 测试 Ollama API
curl http://localhost:11434/api/tags
```

应该返回已安装模型的列表。

## 性能提示

1. **关闭不必要的应用**: Ollama 会使用大量内存
2. **使用合适大小的模型**: 7B 对大多数任务足够
3. **设置 `OLLAMA_NUM_PARALLEL`**: 控制并发请求数
   ```bash
   export OLLAMA_NUM_PARALLEL=1  # 降低内存使用
   ```

## 下一步

一切设置完成后：
1. 确保 `ollama serve` 在运行
2. 运行评估: `python -m art_e.evaluate.benchmark_qwen3`
3. 查看结果并与其他模型对比

## 更多信息

- Ollama 官方文档: https://ollama.ai/docs
- Qwen 模型信息: https://ollama.ai/library/qwen2.5
- GitHub: https://github.com/ollama/ollama

