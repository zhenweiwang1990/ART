# Docker 训练快速参考

## 🚀 快速开始（3 步）

```bash
# 1. 构建镜像（首次，20-30 分钟）
./docker_build.sh

# 2. 配置环境变量
cp .env.template .env
# 编辑 .env，填写密钥

# 3. 运行训练
./docker_run.sh
```

---

## 📋 常用命令

### 本地开发

```bash
# 构建镜像
./docker_build.sh

# 交互式运行
./docker_run.sh

# 后台运行
docker-compose up -d

# 查看日志
docker-compose logs -f

# 停止训练
docker-compose down
```

### 云端部署

```bash
# 1. 推送到 Docker Hub
docker login
docker tag art-e-training:latest your-username/art-e-training:latest
docker push your-username/art-e-training:latest

# 2. 在云端运行
# SSH 到云实例后：
docker pull your-username/art-e-training:latest
docker tag your-username/art-e-training:latest art-e-training:latest
./docker_run_cloud.sh

# 3. 监控
docker logs -f art-e-training
nvidia-smi
```

---

## 🔧 调试命令

```bash
# 进入容器
docker exec -it art-e-training bash

# 查看 GPU
nvidia-smi

# 查看日志
docker logs -f art-e-training

# 查看资源使用
docker stats art-e-training

# 停止容器
docker stop art-e-training

# 重启容器
docker restart art-e-training
```

---

## 📦 镜像管理

```bash
# 查看镜像
docker images | grep art-e

# 删除镜像
docker rmi art-e-training:latest

# 清理缓存
docker builder prune -a

# 导出镜像
docker save art-e-training:latest | gzip > art-e-training.tar.gz

# 导入镜像
gunzip -c art-e-training.tar.gz | docker load
```

---

## ⚠️ 常见问题

| 问题 | 解决方案 |
|------|---------|
| GPU 不可用 | `sudo apt-get install nvidia-docker2` <br> `sudo systemctl restart docker` |
| 内存不足 | 增加 `--shm-size=32g` |
| 构建失败 | `docker builder prune -a` 然后重新构建 |
| 网络慢 | 配置 Docker 镜像加速 |

---

## 📊 文件结构

```
examples/art-e/
├── Dockerfile              # 镜像定义
├── .dockerignore           # 排除文件
├── docker-compose.yml      # Compose 配置
├── docker_build.sh         # 构建脚本
├── docker_run.sh           # 本地运行
├── docker_run_cloud.sh     # 云端运行
├── .env.template           # 环境变量模板
└── .env                    # 环境变量（需创建）
```

---

## 🌐 环境变量

**必需:**
```bash
AWS_ACCESS_KEY_ID=xxx
AWS_SECRET_ACCESS_KEY=xxx
BACKUP_BUCKET=xxx
WANDB_API_KEY=xxx
OPENAI_API_KEY=xxx
```

**可选:**
```bash
KAGGLE_USERNAME=xxx
KAGGLE_KEY=xxx
RUN_ID=xxx
```

---

## 💰 成本

| 项目 | 成本 |
|------|------|
| 构建镜像 | 免费（本地）|
| 存储镜像 | $0-5/月 |
| 运行训练 | $1.64/小时 (A100) |

---

## 📚 详细文档

查看 `DOCKER_TRAINING_GUIDE.md` 获取完整文档。

