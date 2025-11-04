# ART-E Docker 训练指南

使用 Docker 容器化训练环境，避免复杂的依赖配置。

## 目录

- [前置要求](#前置要求)
- [快速开始](#快速开始)
- [本地训练](#本地训练)
- [云端训练](#云端训练)
- [故障排查](#故障排查)

---

## 前置要求

### 1. 安装 Docker

**Ubuntu/Linux:**
```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
```

**macOS:**
```bash
brew install --cask docker
```

### 2. 安装 NVIDIA Docker 运行时

**仅 Linux（macOS 不支持 GPU）:**
```bash
# 安装 NVIDIA Container Toolkit
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list

sudo apt-get update
sudo apt-get install -y nvidia-docker2
sudo systemctl restart docker
```

**验证 GPU 可用性:**
```bash
docker run --rm --gpus all nvidia/cuda:12.4.1-base-ubuntu22.04 nvidia-smi
```

### 3. 配置环境变量

```bash
cd examples/art-e
cp .env.template .env
# 编辑 .env 文件，填写必要的密钥
```

**必需的环境变量:**
```bash
AWS_ACCESS_KEY_ID=your_aws_access_key
AWS_SECRET_ACCESS_KEY=your_aws_secret_key
BACKUP_BUCKET=your_s3_bucket_name
WANDB_API_KEY=your_wandb_key
OPENAI_API_KEY=your_openai_key
```

---

## 快速开始

### 构建镜像

```bash
cd examples/art-e
chmod +x docker_build.sh
./docker_build.sh
```

构建时间约 **20-30 分钟**（取决于网络速度）。

### 运行训练

```bash
chmod +x docker_run.sh
./docker_run.sh
```

---

## 本地训练

### 方式 1: 使用脚本（推荐）

```bash
# 交互式运行
./docker_run.sh

# 自定义参数
./docker_run.sh python art_e/train.py --model agent_002
```

### 方式 2: 使用 Docker Compose

```bash
# 启动训练
docker-compose up

# 后台运行
docker-compose up -d

# 查看日志
docker-compose logs -f

# 停止训练
docker-compose down
```

### 方式 3: 手动运行

```bash
docker run --gpus all \
  --env-file .env \
  -v $(pwd)/data:/workspace/examples/art-e/data \
  -v $(pwd)/outputs:/workspace/examples/art-e/outputs \
  --shm-size=16g \
  --rm -it \
  art-e-training:latest
```

---

## 云端训练

### RunPod / Lambda Labs / Vast.ai

#### 1. 推送镜像到 Docker Hub

```bash
# 登录 Docker Hub
docker login

# 标记镜像
docker tag art-e-training:latest your-username/art-e-training:latest

# 推送镜像
docker push your-username/art-e-training:latest
```

#### 2. 在云实例上运行

**SSH 连接到云实例后:**

```bash
# 拉取镜像
docker pull your-username/art-e-training:latest
docker tag your-username/art-e-training:latest art-e-training:latest

# 创建 .env 文件
cat > .env << 'EOF'
AWS_ACCESS_KEY_ID=xxx
AWS_SECRET_ACCESS_KEY=xxx
BACKUP_BUCKET=xxx
WANDB_API_KEY=xxx
OPENAI_API_KEY=xxx
EOF

# 运行训练
chmod +x docker_run_cloud.sh
./docker_run_cloud.sh
```

#### 3. 监控训练

```bash
# 查看实时日志
docker logs -f art-e-training

# 查看 GPU 使用
watch -n 1 nvidia-smi

# 进入容器
docker exec -it art-e-training bash
```

### 使用 SkyPilot 自动化部署

创建 `sky_docker.yaml`:

```yaml
name: art-e-docker-training

resources:
  accelerators: A100:1
  cloud: runpod
  disk_size: 512

setup: |
  # 安装 Docker（如果需要）
  if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com | sh
  fi
  
  # 拉取镜像
  docker pull your-username/art-e-training:latest
  docker tag your-username/art-e-training:latest art-e-training:latest

run: |
  cd ~/examples/art-e
  
  # 创建 .env
  cat > .env << 'EOF'
  AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
  AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
  BACKUP_BUCKET=$BACKUP_BUCKET
  WANDB_API_KEY=$WANDB_API_KEY
  OPENAI_API_KEY=$OPENAI_API_KEY
  EOF
  
  # 运行训练
  docker run --gpus all --env-file .env \
    -v $(pwd)/data:/workspace/examples/art-e/data \
    -v $(pwd)/outputs:/workspace/examples/art-e/outputs \
    --shm-size=16g --ipc=host \
    art-e-training:latest

envs:
  AWS_ACCESS_KEY_ID: your_key
  AWS_SECRET_ACCESS_KEY: your_secret
  BACKUP_BUCKET: your_bucket
  WANDB_API_KEY: your_key
  OPENAI_API_KEY: your_key
```

**启动:**
```bash
sky launch -c art-e-docker sky_docker.yaml
```

---

## 镜像管理

### 查看镜像

```bash
docker images | grep art-e-training
```

### 删除镜像

```bash
docker rmi art-e-training:latest
```

### 清理构建缓存

```bash
docker builder prune -a
```

### 导出/导入镜像（离线传输）

```bash
# 导出
docker save art-e-training:latest | gzip > art-e-training.tar.gz

# 传输到云端
scp art-e-training.tar.gz user@remote:/path/

# 在云端导入
gunzip -c art-e-training.tar.gz | docker load
```

---

## 优化建议

### 1. 多阶段构建（减小镜像大小）

当前镜像较大（约 15-20 GB），可以通过多阶段构建优化：

```dockerfile
# 使用 BuildKit 缓存
# export DOCKER_BUILDKIT=1
```

### 2. 使用私有镜像仓库

**AWS ECR:**
```bash
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 123456789.dkr.ecr.us-east-1.amazonaws.com

docker tag art-e-training:latest 123456789.dkr.ecr.us-east-1.amazonaws.com/art-e-training:latest
docker push 123456789.dkr.ecr.us-east-1.amazonaws.com/art-e-training:latest
```

### 3. 缓存依赖层

在 Dockerfile 中先复制依赖文件，后复制代码：

```dockerfile
# 先复制依赖文件（变化较少）
COPY pyproject.toml uv.lock ./
RUN uv sync

# 后复制代码（变化较多）
COPY . .
```

---

## 故障排查

### 问题 1: GPU 不可用

**症状:**
```
docker: Error response from daemon: could not select device driver "" with capabilities: [[gpu]]
```

**解决:**
```bash
# 检查 NVIDIA 驱动
nvidia-smi

# 重装 nvidia-docker2
sudo apt-get remove nvidia-docker2
sudo apt-get install nvidia-docker2
sudo systemctl restart docker
```

### 问题 2: 内存不足

**症状:**
```
RuntimeError: CUDA out of memory
```

**解决:**
```bash
# 增加共享内存
docker run --shm-size=32g ...

# 或在 docker-compose.yml 中
shm_size: '32gb'
```

### 问题 3: 构建失败

**症状:**
```
ERROR: failed to solve: process "/bin/sh -c uv pip install ..." did not complete successfully
```

**解决:**
```bash
# 清理缓存重新构建
docker builder prune -a
./docker_build.sh
```

### 问题 4: 容器无法访问 .env

**解决:**
```bash
# 确保 .env 文件存在且有正确权限
ls -la .env
chmod 644 .env

# 或直接传递环境变量
docker run -e AWS_ACCESS_KEY_ID=xxx -e AWS_SECRET_ACCESS_KEY=xxx ...
```

### 问题 5: 网络问题（中国大陆）

**解决:**
```bash
# 使用镜像加速
# 编辑 /etc/docker/daemon.json
{
  "registry-mirrors": [
    "https://docker.mirrors.ustc.edu.cn",
    "https://hub-mirror.c.163.com"
  ]
}

sudo systemctl restart docker
```

---

## 性能对比

| 方式 | 构建时间 | 启动时间 | 灵活性 | 推荐场景 |
|------|---------|---------|--------|---------|
| Docker | 20-30 分钟（一次） | 1-2 分钟 | 低 | 生产环境、云端批量部署 |
| 手动安装 | 10-15 分钟（每次） | - | 高 | 本地开发、调试 |
| SkyPilot + 脚本 | 15-20 分钟（每次） | 5-10 分钟 | 中 | 云端快速实验 |

---

## 成本估算

**构建镜像（一次性）:**
- 本地构建: 免费
- 云端构建: 约 $0.5-1（使用构建服务器 30 分钟）

**存储镜像:**
- Docker Hub: 免费（公开）/ $5/月（私有）
- AWS ECR: $0.10/GB/月（约 $2/月）

**运行训练:**
- 与直接运行相同（A100: $1.64/小时）

---

## 总结

✅ **优点:**
- 环境一致性，避免依赖冲突
- 快速部署到多台机器
- 易于版本管理和回滚
- 隔离性好，不影响宿主机

⚠️ **缺点:**
- 镜像较大（15-20 GB）
- 构建时间较长（首次）
- 调试稍微复杂

**推荐使用场景:**
1. 生产环境训练
2. 多机器批量部署
3. 云端临时实例
4. CI/CD 自动化训练

