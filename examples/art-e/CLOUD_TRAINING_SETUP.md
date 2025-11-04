# 云端训练完整设置指南

## 📋 前置准备清单

在开始之前，你需要准备以下账号和服务：

- [ ] AWS 账号（用于 S3 存储）
- [ ] Weights & Biases 账号（用于训练监控）
- [ ] OpenAI API key（用于答案判断）
- [ ] RunPod 账号（用于 GPU 租赁，可选其他云提供商）

---

## 🔑 第一步：获取所需的 API Keys

### 1.1 AWS S3（必需）

用于保存模型检查点和训练日志。

```bash
# 如果还没有 AWS 账号
# 1. 访问 https://aws.amazon.com/
# 2. 注册账号（需要信用卡）
# 3. 创建 IAM 用户并获取访问密钥

# 创建 S3 存储桶
aws s3 mb s3://your-art-training-bucket --region us-east-1

# 或者使用 AWS 控制台创建：
# https://s3.console.aws.amazon.com/s3/bucket/create
```

**获取 AWS 凭证：**
- 访问 https://console.aws.amazon.com/iam/home#/security_credentials
- 创建访问密钥（Access Key）
- 记录 `AWS_ACCESS_KEY_ID` 和 `AWS_SECRET_ACCESS_KEY`

**预计成本：** S3 存储约 $0.023/GB/月，一次训练约几 GB

### 1.2 Weights & Biases（强烈推荐）

用于可视化训练进度和指标。

```bash
# 1. 访问 https://wandb.ai/signup
# 2. 免费注册（个人账号永久免费）
# 3. 获取 API key: https://wandb.ai/settings

# 测试 W&B
wandb login your-api-key
```

**预计成本：** 免费（个人账号）

### 1.3 OpenAI API（必需）

用于评估答案的正确性（使用 GPT-4o 作为裁判）。

```bash
# 1. 访问 https://platform.openai.com/signup
# 2. 添加付费方式
# 3. 获取 API key: https://platform.openai.com/api-keys
```

**预计成本：** 评估 100 个样本约 $0.5-1

### 1.4 RunPod/GPU 云提供商

```bash
# RunPod（推荐，价格实惠）
# 1. 访问 https://www.runpod.io/
# 2. 注册并充值（建议先充 $20）
# 3. 按照下面的步骤配置 SkyPilot
```

**GPU 成本对比：**
- **A10G (24GB)**: ~$0.50/hour → 约 $5-10 完整训练 ⭐ 推荐
- **A100-40GB**: ~$1.50/hour → 约 $15-30 完整训练
- **A100-80GB**: ~$2.50/hour → 约 $25-50 完整训练
- **H100**: ~$3.50/hour → 约 $35-70 完整训练

---

## 🛠️ 第二步：配置 SkyPilot

SkyPilot 是一个多云 GPU 编排工具，已集成在项目中。

### 2.1 安装 SkyPilot CLI

```bash
# 已经通过 uv 安装，验证一下
sky check

# 如果遇到问题，重新安装
uv pip install "skypilot[runpod]"
```

### 2.2 配置 RunPod

```bash
# 1. 获取 RunPod API key
# 访问 https://www.runpod.io/console/user/settings
# 复制你的 API key

# 2. 配置 SkyPilot
sky check runpod

# 3. 按照提示输入 API key
# SkyPilot 会自动保存到 ~/.sky/config.yaml
```

### 2.3 测试连接

```bash
# 列出可用的 GPU
sky show-gpus --cloud runpod

# 应该能看到类似输出：
# A10G       24GB   $0.50/hr
# A100-40GB  40GB   $1.50/hr
# ...
```

---

## ⚙️ 第三步：配置环境变量

### 3.1 创建 .env 文件

```bash
cd /Users/zhenwei/workspace/ART/examples/art-e

# 复制模板
cp .env.template .env

# 编辑 .env 文件
nano .env
# 或使用你喜欢的编辑器
```

### 3.2 填写配置

编辑 `.env` 文件，填入实际的值：

```bash
# S3 配置
BACKUP_BUCKET=your-art-training-bucket      # 你创建的 S3 桶名
AWS_ACCESS_KEY_ID=AKIA...                   # AWS 访问密钥
AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI...      # AWS 密钥
AWS_REGION=us-east-1

# 训练监控
WANDB_API_KEY=1234567890abcdef...           # W&B API key

# 答案评估
OPENAI_API_KEY=sk-proj-...                  # OpenAI API key

# 可选
OPENPIPE_API_KEY=opk_...                    # 如果有的话
HF_HUB_ENABLE_HF_TRANSFER=1
```

### 3.3 验证配置

```bash
# 测试 AWS S3 访问
export $(cat .env | xargs)
aws s3 ls s3://$BACKUP_BUCKET

# 测试 W&B
wandb login $WANDB_API_KEY

# 测试 OpenAI
curl https://api.openai.com/v1/models \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  | grep -q "gpt-4o" && echo "✅ OpenAI API 正常"
```

---

## 🚀 第四步：启动训练

### 4.1 选择训练配置

查看 `train.py` 中的可用配置：

```python
# agent_002: 基础配置（14B 模型，1 epoch）
# agent_004: 增加 max_turns 到 30
# agent_007: 启用工具使用
# agent_008: 更多 epochs 和训练轮次（推荐）
# agent_013: 大批次训练
# agent_014: 简单奖励函数
```

### 4.2 启动训练任务

```bash
cd /Users/zhenwei/workspace/ART/examples/art-e

# 使用 A10G GPU（便宜，推荐初次尝试）
uv run run_training_job.py 002 --fast --accelerator "A10G:1"

# 或使用更快的 A100
uv run run_training_job.py 008 --fast --accelerator "A100-40GB:1"

# 参数说明：
# 002 / 008 / etc.  - 配置 ID（对应 train.py 中的 agent_XXX）
# --fast            - 快速启动（如果集群已存在则跳过配置）
# --accelerator     - GPU 类型和数量
# --idle-minutes 60 - 闲置 60 分钟后自动关闭（节省成本）
```

### 4.3 启动后会发生什么

```
✅ 1. SkyPilot 在 RunPod 上创建 GPU 实例
✅ 2. 安装依赖和下载模型（约 10-15 分钟）
✅ 3. 从 S3 拉取之前的检查点（如果有）
✅ 4. 开始训练
   - 每 30 步评估一次
   - 自动保存检查点到 S3
   - 实时上传指标到 W&B
✅ 5. 训练完成后自动关闭实例
```

---

## 📊 第五步：监控训练

### 5.1 查看实时日志

```bash
# 方法 1: 在启动命令的终端中查看
# 日志会实时流式输出

# 方法 2: 在另一个终端中连接
sky logs kyle-email-agent-002 --follow

# 方法 3: SSH 到训练实例
sky ssh kyle-email-agent-002
cd ART/examples/art-e
tail -f nohup.out
```

### 5.2 Weights & Biases Dashboard

```bash
# 1. 访问 https://wandb.ai/
# 2. 进入你的项目（email_agent）
# 3. 查看实时训练曲线

重要指标：
- train/policy_loss       # 训练损失（应该下降）
- val/reward              # 验证奖励（应该上升到 1.0+）
- val/answer_correct      # 答案准确率（目标 0.85+）
- val/num_turns           # 平均轮数（应该下降）
- val/cant_parse_tool_call # 工具调用错误率（应该接近 0）
```

### 5.3 检查训练状态

```bash
# 查看正在运行的任务
sky queue

# 查看集群状态
sky status

# 示例输出：
# NAME                    LAUNCHED    RESOURCES     STATUS  
# kyle-email-agent-002   5 mins ago  1x A10G       UP
```

---

## 🛑 第六步：管理训练任务

### 6.1 暂停训练（保存进度）

```bash
# 训练会自动保存到 S3，可以安全中断
sky down kyle-email-agent-002

# 稍后恢复训练（会从最新检查点继续）
uv run run_training_job.py 002 --fast
```

### 6.2 查看成本

```bash
# 查看花费
sky cost-report

# RunPod Dashboard
# 访问 https://www.runpod.io/console/billing
```

### 6.3 清理资源

```bash
# 停止并删除集群
sky down kyle-email-agent-002 --purge

# 查看 S3 使用情况
aws s3 ls s3://$BACKUP_BUCKET --recursive --human-readable --summarize
```

---

## 🎓 第七步：评估训练结果

### 7.1 下载检查点

```bash
# 从 S3 下载训练好的模型
aws s3 sync s3://$BACKUP_BUCKET/.art/email_agent/email-agent-002 \
  ./.art/email_agent/email-agent-002
```

### 7.2 评估模型

```python
# 创建评估脚本 eval_trained_model.py
import art
import asyncio
from art_e.evaluate.benchmark import benchmark_model
from art_e.project_types import ProjectPolicyConfig

async def evaluate():
    # 加载训练好的模型
    model = art.TrainableModel(
        name="email-agent-002",
        project="email_agent",
        base_model="Qwen/Qwen2.5-14B-Instruct",
        config=ProjectPolicyConfig(max_turns=10, use_tools=True),
    )
    
    api = art.LocalAPI()
    await model.register(api)
    
    # 运行评估
    results = await benchmark_model(model, limit=100)
    print(results)

asyncio.run(evaluate())
```

### 7.3 与基线比较

在 W&B 中比较：
- 你训练的模型
- GPT-4o
- Claude 3.5 Sonnet
- 基础 Qwen 模型（未训练）

---

## 💰 成本估算

### 一次完整训练（agent_002 配置）：

```
基础配置（14B 模型，4000 样本，1 epoch）：

GPU（A10G）:
- 训练时间: 约 10-15 小时
- 成本: $5-8

其他服务：
- S3 存储: $0.5
- OpenAI API（评估）: $1-2
- 数据传输: $1

总计：约 $8-12 / 次训练
```

### 节省成本的技巧：

1. **使用 Spot 实例**（如果支持）可节省 50-70%
2. **减少评估频率**（eval_steps=50 而不是 30）
3. **使用更小的模型**（Qwen2.5-7B）
4. **减少训练数据量**（training_dataset_size=2000）

---

## ❓ 常见问题

### Q1: 训练卡住不动了怎么办？

```bash
# 查看详细日志
sky logs kyle-email-agent-002 --follow

# SSH 进入查看
sky ssh kyle-email-agent-002
nvidia-smi  # 查看 GPU 使用
htop        # 查看 CPU/内存
```

### Q2: 显存不足（OOM）错误

编辑 `train.py`，减少批次大小：

```python
training_config=TrainingConfig(
    trajectories_per_group=3,  # 从 6 降到 3
    groups_per_step=4,         # 从 8 降到 4
)
```

### Q3: S3 访问权限问题

```bash
# 检查 IAM 权限
aws s3 ls s3://$BACKUP_BUCKET

# 确保有以下权限：
# - s3:PutObject
# - s3:GetObject
# - s3:ListBucket
```

### Q4: 如何在多个配置间切换？

```bash
# 停止当前训练
sky down kyle-email-agent-002

# 启动新配置
uv run run_training_job.py 008 --fast
```

---

## 📚 参考资源

- **SkyPilot 文档**: https://skypilot.readthedocs.io/
- **RunPod 文档**: https://docs.runpod.io/
- **W&B 文档**: https://docs.wandb.ai/
- **项目原始博客**: https://openpipe.ai/blog/art-e-mail-agent

---

## ✅ 快速启动检查清单

在启动训练前，确保：

- [ ] AWS S3 存储桶已创建
- [ ] `.env` 文件已配置所有必需的 API keys
- [ ] SkyPilot 已配置 RunPod（或其他云提供商）
- [ ] W&B 账号已登录
- [ ] 已选择合适的 GPU 类型和配置
- [ ] 预算充足（建议至少 $20）

准备好了？运行：

```bash
uv run run_training_job.py 002 --fast --accelerator "A10G:1"
```

祝训练顺利！🎉


