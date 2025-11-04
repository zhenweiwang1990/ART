# 🚀 ART-E 训练命令速查表

## 📦 Docker 镜像管理

```bash
# 构建镜像
./docker_build.sh
# 或
make build

# 推送到 Docker Hub
./docker_push_only.sh
# 或
make push

# 构建并推送
./docker_build_and_push.sh
# 或
make build-push

# 本地运行
./docker_run.sh
# 或
make run

# 查看镜像
docker images art-e-training:latest

# 删除镜像
docker rmi art-e-training:latest

# 监控构建
./watch_build.sh
```

---

## ☁️ RunPod 部署

### Web UI 方式

```bash
# 1. 准备环境变量
cp env.template .env
vim .env

# 2. 访问 RunPod 创建 Pod
# https://www.runpod.io/console/pods

# 3. 在 Pod 内启动训练
./start_runpod_training.sh
```

### SkyPilot 方式

```bash
# 修改配置文件
vim sky_runpod_docker.yaml  # 替换 YOUR_USERNAME

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

### 直接 SSH 方式

```bash
# SSH 连接到 RunPod Pod
ssh root@XX.XX.XX.XX -p XXXXX -i ~/.ssh/runpod

# 在 Pod 内
docker pull YOUR_USERNAME/art-e-training:latest

# 创建 .env 文件
cat > .env << EOF
AWS_ACCESS_KEY_ID=your_key
AWS_SECRET_ACCESS_KEY=your_secret
WANDB_API_KEY=your_wandb_key
EOF

# 运行训练
docker run --rm --gpus all \
  --env-file .env \
  -v ~/checkpoints:/workspace/examples/art-e/checkpoints \
  --shm-size 64gb \
  YOUR_USERNAME/art-e-training:latest \
  uv run python art_e/train.py
```

---

## 📊 监控命令

```bash
# 查看 GPU 使用（实时更新）
watch -n 1 nvidia-smi

# 查看训练日志（实时）
tail -f logs/training_*.log

# 查看最新 50 行日志
tail -50 logs/training_*.log

# 查看训练进程
ps aux | grep train.py

# 查看 Docker 容器
docker ps

# 查看容器日志
docker logs art-e-training

# 查看检查点
ls -lh checkpoints/

# 查看 S3 检查点
aws s3 ls s3://your-bucket/art-e-checkpoints/
```

---

## 🛠️ 训练管理

```bash
# 启动训练（前台）
uv run python art_e/train.py

# 启动训练（后台）
nohup uv run python art_e/train.py > training.log 2>&1 &
echo $! > training.pid

# 查看训练进程 ID
cat training.pid

# 停止训练
kill $(cat training.pid)

# 强制停止
kill -9 $(cat training.pid)

# 查看是否在运行
ps -p $(cat training.pid)
```

---

## 🔧 环境管理

```bash
# 检查环境变量
env | grep -E "AWS|WANDB|OPENAI"

# 设置环境变量（临时）
export AWS_ACCESS_KEY_ID=your_key
export WANDB_API_KEY=your_key

# 从 .env 文件加载
set -a
source .env
set +a

# 检查 Python 环境
uv run python --version
uv run python -c "import torch; print(f'PyTorch: {torch.__version__}')"
uv run python -c "import torch; print(f'CUDA: {torch.cuda.is_available()}')"

# 安装依赖
uv sync

# 更新依赖
uv sync --upgrade
```

---

## 📈 Weights & Biases

```bash
# 登录 W&B
wandb login

# 查看项目
wandb project art-e-email-agent

# 下载运行数据
wandb download YOUR_USERNAME/art-e-email-agent/RUN_ID

# 访问 Web UI
# https://wandb.ai/YOUR_USERNAME/art-e-email-agent
```

---

## 💾 数据管理

```bash
# 生成邮件数据库
uv run python -c "from art_e.data.local_email_db import generate_database; generate_database(overwrite=True)"

# 处理 Enron 数据集
uv run python -m art_e.data.convert_enron_email_dataset --max-emails 10000

# 查看数据库
sqlite3 data/enron_emails.db "SELECT COUNT(*) FROM emails;"

# 备份检查点到 S3
aws s3 sync checkpoints/ s3://your-bucket/art-e-checkpoints/

# 从 S3 恢复检查点
aws s3 sync s3://your-bucket/art-e-checkpoints/ checkpoints/
```

---

## 🧪 测试与评估

```bash
# 运行评估
uv run python art_e/evaluate/benchmark.py

# 评估特定模型
uv run python -c "
from art_e.evaluate.benchmark import benchmark_model
import asyncio
asyncio.run(benchmark_model('gpt-4o'))
"

# 快速测试
uv run python -c "import art; print('✅ ART imported')"

# 测试 GPU
uv run python -c "import torch; print(torch.cuda.is_available())"
```

---

## 🐛 故障排除

```bash
# 检查 Docker 服务
docker info
docker ps -a

# 清理 Docker 缓存
docker system prune -f
docker builder prune -f

# 查看 Docker 镜像大小
docker images --format "{{.Repository}}:{{.Tag}} {{.Size}}"

# 检查磁盘空间
df -h
du -sh checkpoints/ output/ wandb/

# 查看系统资源
htop
# 或
top

# 检查网络
ping 8.8.8.8
curl -I https://api.wandb.ai

# 测试 S3 连接
aws s3 ls
```

---

## 📂 文件管理

```bash
# 创建必要目录
mkdir -p checkpoints output wandb logs data

# 清理日志
rm -f logs/*.log

# 清理检查点（危险！）
# rm -rf checkpoints/*

# 压缩检查点
tar -czf checkpoints_backup.tar.gz checkpoints/

# 解压检查点
tar -xzf checkpoints_backup.tar.gz

# 查看目录大小
du -sh */
```

---

## 🔐 安全管理

```bash
# 检查 .env 是否在 .gitignore
cat .gitignore | grep .env

# 检查敏感文件权限
ls -la .env

# 设置 .env 权限（仅所有者可读）
chmod 600 .env

# 检查是否有 .env 被提交
git log --all -- .env

# 从 Git 历史中删除敏感文件（危险！）
# git filter-branch --force --index-filter \
#   "git rm --cached --ignore-unmatch .env" \
#   --prune-empty --tag-name-filter cat -- --all
```

---

## ⚡ 快捷命令（Make）

```bash
# 查看所有命令
make help

# 构建镜像
make build

# 运行本地测试
make run

# 运行云端训练
make run-cloud

# 推送镜像
make push

# 构建并推送
make build-push

# 清理容器
make clean
```

---

## 🎯 常用组合命令

```bash
# 完整构建流程
./docker_build.sh && ./docker_push_only.sh

# 构建、推送、启动
make build-push && sky launch -c art-e-docker sky_runpod_docker.yaml

# 查看训练状态（组合）
echo "=== GPU ===" && nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total --format=csv && \
echo -e "\n=== Process ===" && ps aux | grep train.py | grep -v grep && \
echo -e "\n=== Latest Log ===" && tail -10 logs/training_*.log

# 完整清理
docker stop $(docker ps -q) && docker system prune -f && rm -f training.pid
```

---

## 📚 快速参考

| 任务 | 命令 |
|------|------|
| **构建镜像** | `./docker_build.sh` |
| **推送镜像** | `./docker_push_only.sh` |
| **启动训练** | `./start_runpod_training.sh` |
| **查看日志** | `tail -f logs/training_*.log` |
| **查看 GPU** | `watch -n 1 nvidia-smi` |
| **停止训练** | `kill $(cat training.pid)` |
| **监控 W&B** | https://wandb.ai |

---

## 🔗 有用的链接

- **RunPod Console**: https://www.runpod.io/console/pods
- **Docker Hub**: https://hub.docker.com
- **Weights & Biases**: https://wandb.ai
- **AWS S3 Console**: https://console.aws.amazon.com/s3

---

**保存此文件以便快速查阅！** 📌

