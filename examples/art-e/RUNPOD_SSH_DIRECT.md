# 🚀 直接通过 SSH 在 RunPod 上运行训练

## 情况说明

你的 RunPod 服务器已经启动并且 SSH 可用，但 SkyPilot 的自动连接比较慢。

**最简单的解决方案**：直接 SSH 连接上去手动运行！

---

## ✅ 快速启动（5 分钟）

### 步骤 1: SSH 连接到服务器

```bash
ssh -i ~/.ssh/sky-key root@69.30.85.62 -p 22097
```

### 步骤 2: 拉取 Docker 镜像

```bash
# 替换 YOUR_USERNAME 为你的 Docker Hub 用户名
docker pull YOUR_USERNAME/art-e-training:latest
```

### 步骤 3: 创建环境变量文件

```bash
# 创建 .env 文件
cat > .env << 'EOF'
AWS_ACCESS_KEY_ID=your_access_key_here
AWS_SECRET_ACCESS_KEY=your_secret_key_here
AWS_DEFAULT_REGION=us-west-2
WANDB_API_KEY=your_wandb_key_here
WANDB_PROJECT=art-e-email-agent
IMPORT_UNSLOTH=0
EOF

# 编辑并填写真实的值
vim .env
```

### 步骤 4: 创建目录

```bash
mkdir -p checkpoints output wandb logs
```

### 步骤 5: 启动训练

```bash
# 替换 YOUR_USERNAME
docker run --rm --gpus all \
  --env-file .env \
  -v ~/checkpoints:/workspace/examples/art-e/checkpoints \
  -v ~/output:/workspace/examples/art-e/output \
  -v ~/wandb:/workspace/examples/art-e/wandb \
  --shm-size 64gb \
  --name art-e-training \
  YOUR_USERNAME/art-e-training:latest \
  uv run python art_e/train.py
```

**完成！** 🎉

---

## 🔄 后台运行（推荐）

如果想后台运行，可以断开连接：

```bash
# 后台运行
nohup docker run --rm --gpus all \
  --env-file .env \
  -v ~/checkpoints:/workspace/examples/art-e/checkpoints \
  -v ~/output:/workspace/examples/art-e/output \
  -v ~/wandb:/workspace/examples/art-e/wandb \
  --shm-size 64gb \
  --name art-e-training \
  YOUR_USERNAME/art-e-training:latest \
  uv run python art_e/train.py > logs/training.log 2>&1 &

# 保存进程 ID
echo $! > training.pid

echo "✅ 训练已在后台启动！"
echo "进程 ID: $(cat training.pid)"
```

---

## 📊 监控训练

### 查看日志

```bash
# 实时查看
tail -f logs/training.log

# 查看最新 100 行
tail -100 logs/training.log
```

### 查看 GPU

```bash
watch -n 1 nvidia-smi
```

### 查看进程

```bash
ps aux | grep train.py
docker ps
```

### Weights & Biases

访问：
```
https://wandb.ai/YOUR_USERNAME/art-e-email-agent
```

---

## 🛑 停止训练

```bash
# 停止 Docker 容器
docker stop art-e-training

# 或使用进程 ID
kill $(cat training.pid)
```

---

## 🔄 断开连接后重新连接

```bash
# 重新 SSH 连接
ssh -i ~/.ssh/sky-key root@69.30.85.62 -p 22097

# 查看训练是否在运行
docker ps
ps aux | grep train.py

# 查看日志
tail -f logs/training.log
```

---

## 💡 提示

### SSH 连接信息

- **主机**: 69.30.85.62
- **端口**: 22097
- **Key**: ~/.ssh/sky-key
- **用户**: root

### 保存 SSH 配置（可选）

在 `~/.ssh/config` 添加：

```
Host runpod-art-e
    HostName 69.30.85.62
    Port 22097
    User root
    IdentityFile ~/.ssh/sky-key
    StrictHostKeyChecking no
```

然后就可以简单地使用：
```bash
ssh runpod-art-e
```

---

## ❓ 常见问题

### Q: Docker 镜像拉取很慢？

A: RunPod 的网速取决于数据中心位置。首次拉取 10GB 镜像需要 5-10 分钟。

### Q: 如何查看训练进度？

A: 
1. **Weights & Biases**: https://wandb.ai (推荐)
2. **日志**: `tail -f logs/training.log`
3. **GPU**: `nvidia-smi`

### Q: 训练完成后如何获取模型？

A:
1. 检查点会保存到 S3（如果配置了 AWS）
2. 或从 `~/checkpoints/` 目录下载

### Q: 如何从本地复制文件到服务器？

```bash
# 上传文件
scp -i ~/.ssh/sky-key -P 22097 local_file.txt root@69.30.85.62:~/

# 下载文件
scp -i ~/.ssh/sky-key -P 22097 root@69.30.85.62:~/remote_file.txt .
```

---

## 🎯 与 SkyPilot 的区别

| 特性 | SkyPilot | 直接 SSH |
|------|----------|---------|
| **设置复杂度** | 中等 | 简单 |
| **自动化** | 高 | 低 |
| **启动速度** | 慢（有时卡住） | 快（立即） |
| **灵活性** | 中等 | 高 |
| **推荐场景** | 频繁重复训练 | 快速测试、调试 |

---

## ✅ 总结

使用直接 SSH 方式：
- ✅ **更快**: 立即连接，不等待
- ✅ **更简单**: 直接运行 Docker 命令
- ✅ **更灵活**: 完全控制
- ✅ **更可靠**: 不依赖 SkyPilot 的连接逻辑

**现在就试试吧！** 🚀

```bash
ssh -i ~/.ssh/sky-key root@69.30.85.62 -p 22097
```

