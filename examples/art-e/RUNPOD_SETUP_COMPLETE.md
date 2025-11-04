# ✅ RunPod 训练环境设置完成

## 🎉 恭喜！所有准备工作已完成

你现在拥有一个完整的、生产级的训练环境，可以在 RunPod 上快速部署！

---

## 📦 已创建的文件

### 核心文档

| 文件 | 说明 | 推荐度 |
|------|------|--------|
| **`RUNPOD_QUICKSTART.md`** | 快速启动指南 | ⭐⭐⭐ 必读 |
| **`RUNPOD_TRAINING_GUIDE.md`** | 完整详细指南 | ⭐⭐⭐ 必读 |
| `env.template` | 环境变量模板 | ⭐⭐⭐ 必需 |

### 配置文件

| 文件 | 说明 |
|------|------|
| `sky_runpod_docker.yaml` | SkyPilot 配置（自动化部署） |
| `Dockerfile` | Docker 镜像定义 |
| `.dockerignore` | Docker 构建排除文件 |
| `docker-compose.yml` | Docker Compose 配置 |

### 脚本文件

| 文件 | 用途 |
|------|------|
| **`start_runpod_training.sh`** | ⭐ RunPod Pod 内启动训练 |
| `docker_build.sh` | 构建 Docker 镜像 |
| `docker_push_only.sh` | 推送镜像到 Docker Hub |
| `docker_build_and_push.sh` | 构建并推送 |
| `docker_run.sh` | 本地运行 |
| `docker_run_cloud.sh` | 云端后台运行 |
| `watch_build.sh` | 监控 Docker 构建 |
| `Makefile` | Make 命令快捷方式 |

---

## 🚀 3 步开始训练

### 步骤 1: 准备环境变量

```bash
cd examples/art-e

# 复制模板
cp env.template .env

# 编辑 .env 文件，填写:
# - AWS_ACCESS_KEY_ID
# - AWS_SECRET_ACCESS_KEY
# - WANDB_API_KEY
vim .env
```

### 步骤 2: 在 RunPod 创建 Pod

**访问**: https://www.runpod.io/console/pods

1. 点击 **"+ Deploy"**
2. 选择 **GPU**: A100-80GB
3. **Docker 镜像**: `YOUR_USERNAME/art-e-training:latest`
4. **Container Disk**: 50 GB
5. **环境变量**: 从 `.env` 文件复制
6. 点击 **"Deploy"**

### 步骤 3: 启动训练

Pod 启动后，进入 **Web Terminal**:

```bash
# 直接启动
./start_runpod_training.sh

# 或手动运行
uv run python art_e/train.py
```

**完成！** 🎉

---

## 📊 监控训练

### Weights & Biases（推荐）

训练自动上传到 W&B:

```
https://wandb.ai/YOUR_USERNAME/art-e-email-agent
```

实时查看:
- ✅ Loss 曲线
- ✅ 学习率
- ✅ GPU 使用率
- ✅ 训练进度

### SSH 监控

```bash
# GPU 使用
watch -n 1 nvidia-smi

# 训练日志
tail -f logs/training_*.log
```

---

## 💰 成本估算

| 配置 | 价格 | 时间 | 总成本 |
|------|------|------|--------|
| **A100-80GB On-Demand** | $2.00/小时 | ~12 小时 | **$24** |
| **A100-80GB Spot** | $1.00/小时 | ~12 小时 | **$12** |
| **RTX A6000 Spot** | $0.40/小时 | ~18 小时 | **$7** |

💡 **推荐**:
- **测试**: RTX A5000 Spot (~$3 总成本)
- **正式**: A100-80GB On-Demand (稳定，$24)

---

## 🎯 3 种启动方式对比

### 方法 1: Web UI ⭐⭐⭐（最简单）

**优点**:
- ✅ 图形界面，易操作
- ✅ 5 分钟搞定
- ✅ 适合新手

**缺点**:
- ❌ 每次手动配置

**适合**: 快速测试、新手

---

### 方法 2: SkyPilot ⭐⭐（自动化）

**优点**:
- ✅ 全自动化
- ✅ 可重复使用
- ✅ 多云支持

**缺点**:
- ❌ 需要配置

**适合**: 频繁训练、多次实验

**使用**:
```bash
# 修改 sky_runpod_docker.yaml 中的 YOUR_USERNAME
# 然后一键启动:
sky launch -c art-e-docker sky_runpod_docker.yaml
```

---

### 方法 3: 直接 SSH ⭐（灵活）

**优点**:
- ✅ 完全控制
- ✅ 适合调试

**缺点**:
- ❌ 需要手动操作较多

**适合**: 高级用户、调试

---

## 📚 完整文档导航

### 快速开始
1. **`RUNPOD_QUICKSTART.md`** - 5 分钟快速上手 ⭐
2. **`env.template`** - 配置环境变量

### 详细指南
3. **`RUNPOD_TRAINING_GUIDE.md`** - 完整操作指南
4. **`sky_runpod_docker.yaml`** - SkyPilot 配置示例

### 脚本参考
5. **`start_runpod_training.sh`** - 训练启动脚本
6. **`Makefile`** - Make 命令速查

### 故障排除
- 见 `RUNPOD_TRAINING_GUIDE.md` 的 "🐛 故障排除" 章节

---

## ✅ 检查清单

在启动训练前，确认：

- [ ] Docker 镜像已推送到 Docker Hub
- [ ] 准备好 `.env` 文件（包含所有必需的 API keys）
- [ ] RunPod 账号已充值（至少 $30）
- [ ] 了解如何监控训练（Weights & Biases）
- [ ] 知道如何查看日志（`tail -f logs/training_*.log`）
- [ ] 了解大概的训练时间和成本

**都准备好了？开始吧！** 🚀

---

## 🆘 需要帮助？

### 常见问题

**Q: Docker 镜像太大，拉取很慢？**
A: 首次拉取需要 5-10 分钟，后续会使用缓存，很快。

**Q: 如何查看训练是否在运行？**
A: 
1. Weights & Biases: https://wandb.ai
2. SSH: `ps aux | grep train.py`
3. GPU: `nvidia-smi`

**Q: 训练中断了怎么办？**
A: 
- 检查点会保存到 S3
- 重新启动后可以从检查点恢复（需要修改训练脚本）

**Q: 如何降低成本？**
A:
1. 使用 Spot Instance (便宜 50%)
2. 选择较便宜的 GPU (RTX A5000, A6000)
3. 先用小数据集测试

### 获取支持

1. **查看文档**: `RUNPOD_QUICKSTART.md`
2. **检查日志**: `logs/training_*.log`
3. **查看 W&B**: 检查训练指标
4. **GitHub Issues**: 报告问题

---

## 🎓 下一步

训练完成后:

1. **评估模型**: 见 README.md 的 "Evaluating Models" 部分
2. **分析结果**: 查看 Weights & Biases 的图表
3. **部署模型**: 
   - 从 S3 下载检查点
   - 使用 `art.Model` 加载模型
   - 集成到应用中

---

## 🎉 总结

你现在拥有:

✅ **生产级 Docker 镜像** (10GB, 包含所有依赖)  
✅ **自动化训练脚本** (一键启动)  
✅ **完整文档** (快速开始 + 详细指南)  
✅ **多种部署方式** (Web UI / SkyPilot / SSH)  
✅ **成本优化建议** (~$7-24 完成训练)

**现在就去 RunPod 启动你的训练吧！** 🚀

---

**祝训练顺利！** 🎊

