# 🚀 RunPod 快速启动指南

## 🎯 3 种方法启动训练

### 方法 1: Web UI（最简单）⭐⭐⭐

**5 分钟搞定！**

1. **访问**: https://www.runpod.io/console/pods
2. **点击 "+ Deploy"**
3. **选择 GPU**: A100-80GB (推荐)
4. **配置 Docker 镜像**:
   ```
   Container Image: YOUR_USERNAME/art-e-training:latest
   Container Disk: 50 GB
   ```
5. **添加环境变量**:
   ```bash
   AWS_ACCESS_KEY_ID=your_key
   AWS_SECRET_ACCESS_KEY=your_secret
   WANDB_API_KEY=your_wandb_key
   IMPORT_UNSLOTH=0
   ```
6. **点击 "Deploy"**
7. **等待 Pod 启动** (1-3 分钟)
8. **连接 → Web Terminal**
9. **运行**:
   ```bash
   ./start_runpod_training.sh
   ```

**完成！** 🎉

---

### 方法 2: SkyPilot（推荐自动化）⭐⭐

**10 分钟配置，后续 1 分钟启动！**

#### 首次设置

```bash
cd examples/art-e

# 1. 准备环境变量
cp env.template .env
vim .env  # 填写你的 API keys

# 2. 修改 sky_runpod_docker.yaml
# 将 YOUR_USERNAME 替换为你的 Docker Hub 用户名

# 3. 启动训练
sky launch -c art-e-docker sky_runpod_docker.yaml
```

#### 后续使用

```bash
# 启动
sky launch -c art-e-docker sky_runpod_docker.yaml

# 查看日志
sky logs art-e-docker

# SSH 连接
sky ssh art-e-docker

# 停止
sky down art-e-docker
```

**优点**: 
- ✅ 自动化
- ✅ 可重复
- ✅ 自动上传 .env
- ✅ 多云支持

---

### 方法 3: 直接 SSH 连接

**如果你已经有一个运行的 RunPod Pod**

```bash
# 1. SSH 连接（从 RunPod 控制台获取 SSH 命令）
ssh root@XX.XX.XX.XX -p XXXXX -i ~/.ssh/runpod

# 2. 在 Pod 内拉取镜像
docker pull YOUR_USERNAME/art-e-training:latest

# 3. 创建 .env 文件
cat > .env << EOF
AWS_ACCESS_KEY_ID=your_key
AWS_SECRET_ACCESS_KEY=your_secret
WANDB_API_KEY=your_wandb_key
IMPORT_UNSLOTH=0
EOF

# 4. 运行容器
docker run --rm --gpus all \
  --env-file .env \
  -v ~/checkpoints:/workspace/examples/art-e/checkpoints \
  -v ~/output:/workspace/examples/art-e/output \
  --shm-size 64gb \
  YOUR_USERNAME/art-e-training:latest \
  uv run python art_e/train.py
```

---

## 📋 环境变量配置

### 必需的环境变量

```bash
# AWS (用于保存检查点到 S3)
AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
AWS_DEFAULT_REGION=us-west-2

# Weights & Biases (用于训练监控)
WANDB_API_KEY=1234567890abcdef1234567890abcdef
WANDB_PROJECT=art-e-email-agent

# 可选
IMPORT_UNSLOTH=0
```

### 获取 API Keys

| 服务 | 获取链接 |
|------|---------|
| **AWS** | https://console.aws.amazon.com/iam/home#/security_credentials |
| **Weights & Biases** | https://wandb.ai/authorize |
| **OpenAI** | https://platform.openai.com/api-keys |

---

## 📊 监控训练

### Weights & Biases（推荐）⭐

训练开始后自动上传指标：

```
https://wandb.ai/YOUR_USERNAME/art-e-email-agent
```

可以看到：
- ✅ Loss 曲线
- ✅ 学习率变化
- ✅ GPU 使用率
- ✅ 训练速度
- ✅ 检查点保存记录

### SSH 监控

```bash
# 查看 GPU
watch -n 1 nvidia-smi

# 查看日志
tail -f logs/training_*.log

# 查看进程
ps aux | grep train.py
```

---

## 💰 成本参考

| GPU | 类型 | 价格/小时 | 训练时间 | 总成本 |
|-----|------|----------|---------|--------|
| **A100 80GB** | On-Demand | $2.00 | ~10 小时 | **$20** |
| **A100 80GB** | Spot | $1.00 | ~10 小时 | **$10** |
| **RTX A6000** | On-Demand | $0.80 | ~15 小时 | **$12** |
| **RTX A6000** | Spot | $0.40 | ~15 小时 | **$6** |

**建议**:
- 🎯 **快速测试**: 使用 RTX A5000 Spot (~$0.25/小时)
- 🎯 **正式训练**: 使用 A100-80GB On-Demand (稳定不中断)
- 💰 **省钱**: 使用 Spot Instance (便宜 50%)

---

## 🐛 常见问题

### Q1: Docker 镜像太大，拉取很慢？

**A**: 镜像大小 10GB，首次拉取需要 5-10 分钟（取决于 RunPod 的网速）。后续使用会从 Docker 缓存加载，很快。

### Q2: 环境变量怎么设置？

**A**: 三种方法：
1. **Web UI**: 在创建 Pod 时添加
2. **.env 文件**: 在 Pod 内创建并使用 `--env-file`
3. **SkyPilot**: 在 `file_mounts` 中上传 .env

### Q3: 训练中断怎么办？

**A**: 
- 如果使用 **Spot Instance**，训练可能被中断
- 训练脚本会定期保存检查点到 S3
- 重新启动后可以从检查点恢复（需要修改训练脚本支持恢复）

### Q4: 如何查看训练进度？

**A**:
1. **Weights & Biases**: https://wandb.ai (推荐)
2. **SSH + tail -f logs/training.log**
3. **RunPod Web Terminal**

### Q5: 训练完成后如何获取模型？

**A**:
- 模型会自动保存到 S3（如果配置了 AWS）
- 或者从 Pod 的 `~/checkpoints/` 目录下载
- 使用 `sky storage ls` 查看 SkyPilot 存储

---

## ✅ 快速检查清单

准备启动前确认：

- [ ] Docker 镜像已推送: `YOUR_USERNAME/art-e-training:latest`
- [ ] 准备好 `.env` 文件或环境变量
  - [ ] AWS_ACCESS_KEY_ID
  - [ ] AWS_SECRET_ACCESS_KEY  
  - [ ] WANDB_API_KEY
- [ ] RunPod 账号已充值
- [ ] 选择了合适的 GPU
- [ ] 知道如何监控训练（Weights & Biases）

**都准备好了？开始吧！** 🚀

---

## 🎓 完整文档

- **详细指南**: `RUNPOD_TRAINING_GUIDE.md`
- **SkyPilot 配置**: `sky_runpod_docker.yaml`
- **启动脚本**: `start_runpod_training.sh`
- **环境变量模板**: `env.template`

---

## 🆘 需要帮助？

1. 查看详细文档: `RUNPOD_TRAINING_GUIDE.md`
2. 检查 Docker 镜像构建: `BUILD_SUCCESS.md`
3. 故障排除: 见 `RUNPOD_TRAINING_GUIDE.md` 的故障排除章节

---

**祝训练顺利！** 🎉

