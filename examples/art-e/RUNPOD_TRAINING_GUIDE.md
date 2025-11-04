# 🚀 在 RunPod 上使用 Docker 镜像训练指南

## 📋 前提条件

✅ Docker 镜像已推送到 Docker Hub: `YOUR_USERNAME/art-e-training:latest`  
✅ RunPod 账号  
✅ 准备好环境变量（AWS credentials, Weights & Biases API key 等）

---

## 方法 1: RunPod Web UI（推荐，最简单）⭐

### 步骤 1: 创建 Pod

1. **登录 RunPod**: https://www.runpod.io/console/pods
2. **点击 "+ Deploy"**
3. **选择 GPU**:
   - 推荐: **A100 80GB** (最稳定)
   - 备选: **RTX A6000**, **RTX A5000**
   
### 步骤 2: 配置 Docker 镜像

在 **"Select a Template"** 部分：

1. 点击 **"Custom Template"** 或 **"Edit Template"**
2. 配置如下：

```yaml
Container Image: YOUR_USERNAME/art-e-training:latest
Container Disk: 50 GB  # 至少 50GB
Expose HTTP Ports: 8000  # 可选
Expose TCP Ports: 留空
```

### 步骤 3: 配置环境变量

在 **"Environment Variables"** 部分添加：

```bash
# AWS 凭证（用于 S3 存储检查点）
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key
AWS_DEFAULT_REGION=us-west-2

# Weights & Biases（用于训练监控）
WANDB_API_KEY=your_wandb_api_key
WANDB_PROJECT=art-e-email-agent

# OpenAI API（如果需要）
OPENAI_API_KEY=your_openai_key

# 可选：设置不导入 unsloth（如果遇到问题）
IMPORT_UNSLOTH=0
```

### 步骤 4: 启动 Pod

1. 选择存储空间：
   - **Container Disk**: 50-100 GB
   - **Volume Disk** (可选): 如果需要持久化数据

2. 点击 **"Deploy On-Demand"** 或 **"Deploy Spot"**
   - **On-Demand**: 稳定，不会被中断，价格稍高
   - **Spot**: 便宜 ~50%，但可能被中断

3. 等待 Pod 启动（1-3 分钟）

### 步骤 5: 连接并启动训练

Pod 启动后，点击 **"Connect"** → **"Start Web Terminal"** 或使用 SSH。

在终端中：

```bash
# 查看当前目录
pwd  # 应该是 /workspace/examples/art-e

# 检查 GPU
nvidia-smi

# 启动训练
uv run python art_e/train.py
```

---

## 方法 2: RunPod CLI（适合自动化）

### 安装 RunPod CLI

```bash
pip install runpod
```

### 配置 API Key

1. 在 RunPod 控制台获取 API Key: https://www.runpod.io/console/user/settings
2. 设置环境变量：

```bash
export RUNPOD_API_KEY="your_runpod_api_key"
```

### 创建 Pod（通过 CLI）

创建 `runpod_config.json`:

```json
{
  "cloudType": "SECURE",
  "gpuTypeId": "NVIDIA A100 80GB PCIe",
  "name": "art-e-training",
  "imageName": "YOUR_USERNAME/art-e-training:latest",
  "dockerArgs": "",
  "containerDiskInGb": 50,
  "volumeInGb": 0,
  "env": [
    {"key": "AWS_ACCESS_KEY_ID", "value": "your_access_key"},
    {"key": "AWS_SECRET_ACCESS_KEY", "value": "your_secret_key"},
    {"key": "WANDB_API_KEY", "value": "your_wandb_key"},
    {"key": "IMPORT_UNSLOTH", "value": "0"}
  ],
  "ports": "8000/http"
}
```

启动：

```bash
runpod create pod --config runpod_config.json
```

---

## 方法 3: 使用 SkyPilot（最灵活）⭐

### 创建 SkyPilot 配置文件

创建 `examples/art-e/sky_runpod_docker.yaml`:

```yaml
name: art-e-docker-training

resources:
  cloud: runpod
  accelerators: A100-80GB  # 或 RTXA6000
  disk_size: 100  # GB

file_mounts:
  # 上传 .env 文件（包含敏感信息）
  ~/.config/art-e/.env: .env

setup: |
  # 拉取 Docker 镜像
  docker pull YOUR_USERNAME/art-e-training:latest
  
  # 确保 .env 文件存在
  if [ ! -f ~/.config/art-e/.env ]; then
    echo "错误: .env 文件未找到"
    exit 1
  fi

run: |
  # 运行 Docker 容器进行训练
  docker run --rm --gpus all \
    --env-file ~/.config/art-e/.env \
    -v ~/checkpoints:/workspace/examples/art-e/checkpoints \
    -v ~/output:/workspace/examples/art-e/output \
    -v ~/wandb:/workspace/examples/art-e/wandb \
    --shm-size 64gb \
    YOUR_USERNAME/art-e-training:latest \
    uv run python art_e/train.py
```

### 启动训练

```bash
# 确保 .env 文件已准备好
cp .env.template .env
vim .env  # 填写你的 API keys

# 启动
sky launch -c art-e-docker sky_runpod_docker.yaml

# 查看日志
sky logs art-e-docker

# 查看状态
sky status art-e-docker

# SSH 连接
sky ssh art-e-docker

# 停止并清理
sky down art-e-docker
```

---

## 🔐 安全地管理环境变量

### 选项 1: 使用 .env 文件

创建 `.env` 文件（**不要提交到 Git**）：

```bash
# .env
AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
AWS_DEFAULT_REGION=us-west-2
WANDB_API_KEY=1234567890abcdef
WANDB_PROJECT=art-e-email-agent
OPENAI_API_KEY=sk-...
IMPORT_UNSLOTH=0
```

### 选项 2: 使用 RunPod Secrets

在 RunPod Web UI 中：

1. 进入 **Settings** → **Secrets**
2. 添加密钥
3. 在 Pod 配置中引用密钥

---

## 📊 监控训练进度

### 方法 1: Weights & Biases（推荐）⭐

训练开始后，访问：
```
https://wandb.ai/YOUR_USERNAME/art-e-email-agent
```

实时查看：
- Loss 曲线
- 学习率
- GPU 使用率
- 训练速度

### 方法 2: SSH 连接查看日志

```bash
# 使用 RunPod Web Terminal
# 或 SSH 连接

# 查看 GPU 使用
watch -n 1 nvidia-smi

# 查看训练日志（如果使用后台运行）
tail -f training.log
```

### 方法 3: 查看检查点

训练会定期保存检查点到 S3 或本地：

```bash
# 在 Pod 内
ls -lh checkpoints/

# 或查看 S3
aws s3 ls s3://your-bucket/art-e-checkpoints/
```

---

## 🛠️ 训练脚本

### 后台运行训练（推荐）

在 RunPod Pod 内创建 `start_training.sh`:

```bash
#!/bin/bash

# 设置日志文件
LOG_FILE="training_$(date +%Y%m%d_%H%M%S).log"

# 后台运行训练
nohup uv run python art_e/train.py > "$LOG_FILE" 2>&1 &

# 保存进程 ID
echo $! > training.pid

echo "训练已启动！"
echo "进程 ID: $(cat training.pid)"
echo "日志文件: $LOG_FILE"
echo ""
echo "查看日志: tail -f $LOG_FILE"
echo "停止训练: kill $(cat training.pid)"
```

使用：

```bash
chmod +x start_training.sh
./start_training.sh

# 查看日志
tail -f training_*.log

# 停止训练
kill $(cat training.pid)
```

---

## 💰 成本估算

| GPU | 价格/小时 | 训练时间估算 | 总成本估算 |
|-----|----------|------------|----------|
| **A100 80GB** | $2.00 | ~10-15 小时 | **$20-30** |
| **RTX A6000** | $0.80 | ~15-20 小时 | **$12-16** |
| **RTX A5000** | $0.50 | ~20-25 小时 | **$10-12** |

**建议**: 使用 **Spot Instance** 可节省 ~50% 成本。

---

## 🐛 故障排除

### 问题 1: Docker 镜像拉取失败

```bash
# 手动拉取镜像
docker pull YOUR_USERNAME/art-e-training:latest

# 检查 Docker Hub
docker images
```

### 问题 2: GPU 不可用

```bash
# 检查 GPU
nvidia-smi

# 确保 Docker 使用 GPU
docker run --rm --gpus all nvidia/cuda:12.4.1-base-ubuntu22.04 nvidia-smi
```

### 问题 3: 环境变量未设置

```bash
# 在容器内检查
echo $AWS_ACCESS_KEY_ID
echo $WANDB_API_KEY

# 或列出所有环境变量
env | grep -E "AWS|WANDB|OPENAI"
```

### 问题 4: 内存不足

```bash
# 增加共享内存
docker run --shm-size 64gb ...

# 或在 docker-compose.yml 中设置
shm_size: '64gb'
```

---

## 📁 完整示例脚本

我会创建一个自动化脚本 `runpod_train.sh`，帮你一键启动训练。

---

## ✅ 快速开始检查清单

- [ ] Docker 镜像已推送到 Docker Hub
- [ ] 准备好 `.env` 文件（包含所有 API keys）
- [ ] RunPod 账号已充值
- [ ] 选择了合适的 GPU (推荐 A100-80GB)
- [ ] 设置了 Weights & Biases 用于监控

**现在就可以开始了！** 🚀

---

## 🎯 推荐工作流程

### 快速测试（省钱）

1. 使用 **RTX A5000** ($0.50/小时)
2. **Spot Instance** (再省 50%)
3. 跑 **1-2 个 epoch** 验证流程
4. 成本: ~$2-3

### 正式训练（稳定）

1. 使用 **A100 80GB** ($2.00/小时)
2. **On-Demand Instance** (稳定不中断)
3. 完整训练 **10-15 小时**
4. 成本: ~$20-30

---

**下一步**: 创建自动化启动脚本 `runpod_train.sh` →

