# Qwen3 评估日志分析报告

基于终端输出 (line 681-1023) 的详细分析

---

## 问题 1: Function Call 的数据库查询是否执行了？

### ✅ 回答：是的，查询执行了

**证据：**

从日志可以看到，模型调用了 `search_emails` 工具，查询参数为：
```json
{
  "keywords": ["video conference", "Avi", "Mars Corp."],
  "from_addr": "greg.whalley@enron.com",
  "to_addr": "greg.whalley@enron.com",
  "sent_after": "2000-07-20",
  "sent_before": "2000-07-25",
  "max_results": 10
}
```

**查询结果：** `[]` (空数组)

这说明：
- ✅ 数据库查询**确实执行了**
- ✅ 查询语法**没有错误**（否则会抛异常）
- ❌ 数据库中**没有匹配的邮件**

### 可能的原因：

1. **数据库中确实不存在匹配的邮件**
   - 邮箱地址：greg.whalley@enron.com
   - 日期范围：2000-07-20 到 2000-07-25
   - 关键词：video conference, Avi, Mars Corp.

2. **搜索参数过于严格**
   - 同时指定了 `from_addr` 和 `to_addr` 为同一个人
   - 这意味着只搜索自己发给自己的邮件
   - 但通常会议邀请是别人发来的

3. **FTS 全文搜索的 AND 逻辑**
   - 代码第 76 行：`fts_query = " ".join(f""" "{k.replace('"', '""')}" """ for k in keywords)`
   - 这会要求所有三个关键词都必须出现
   - 可能邮件中没有同时包含这三个词

### 验证建议：

```python
# 检查数据库中是否有这个用户的邮件
SELECT COUNT(*) FROM emails 
WHERE from_address = 'greg.whalley@enron.com' 
OR EXISTS (SELECT 1 FROM recipients WHERE recipient_address = 'greg.whalley@enron.com');

# 检查这个时间段的邮件
SELECT COUNT(*) FROM emails 
WHERE date >= '2000-07-20 00:00:00' AND date < '2000-07-25 00:00:00';

# 检查包含相关关键词的邮件
SELECT message_id, subject FROM emails 
WHERE (subject LIKE '%video%' OR body LIKE '%video%')
AND (subject LIKE '%Avi%' OR body LIKE '%Avi%');
```

---

## 问题 2: Function Call 的结果没有放到后续执行中？

### ❌ 回答：不对，结果**确实**放到了后续执行中

**证据：**

查看完整的对话历史，每次工具调用后都有结果返回：

**第 1 轮：**
- 消息 1-2: system + user query
- 消息 3: assistant 调用 `search_emails` (id: call_357fb...)
- 消息 4: tool 返回 `[]` (响应 call_357fb...)

**第 2 轮：**
- 消息 1-4: (同上)
- 消息 5: assistant **再次**调用 `search_emails` (id: call_7652a...) 
- 消息 6: tool 返回 `[]` (响应 call_7652a...)

**第 3 轮：**
- 消息 1-6: (同上)
- 消息 7: assistant **第三次**调用 `search_emails` (id: call_cc091...)
- 消息 8: tool 返回 `[]` (响应 call_cc091...)

**第 4 轮：**
- 消息 1-8: (同上)
- 消息 9: assistant 调用 `return_final_answer` with "I don't know"

### 真正的问题：模型陷入了重复循环

模型在 3 次调用中**使用了完全相同的参数**：
```json
{
  "keywords": ["video conference", "Avi", "Mars Corp."],
  "from_addr": "greg.whalley@enron.com",
  "to_addr": "greg.whalley@enron.com",
  "sent_after": "2000-07-20",
  "sent_before": "2000-07-25",
  "max_results": 10
}
```

### 期望的行为：

模型应该在收到空结果后**调整搜索策略**，例如：
- ✅ 去掉 `from_addr` 或 `to_addr` 限制
- ✅ 扩大日期范围
- ✅ 减少关键词（只用 "Avi" 或 "Mars Corp"）
- ✅ 尝试不同的关键词组合

### 可能的原因：

1. **模型理解能力不足**
   - Qwen3-32k 可能没有学会如何根据空结果调整搜索策略

2. **Prompt 不够明确**
   - System prompt 没有教模型如何处理空结果
   - 可以添加示例："如果搜索结果为空，尝试放宽搜索条件"

3. **Context 理解问题**
   - 模型可能没有意识到之前的搜索已经失败了

---

## 问题 3: 为什么没看到 GPT-4o 的调用？

### ✅ 回答：这是**预期行为**

**原因：**

模型的最终答案是 `"I don't know"`，根据 `rollout.py` 的逻辑：

```python
# Line 379-386
if final_answer == "I don't know":
    rubric.returned_i_dont_know = True
else:
    rubric.attempted_answer = True
    rubric.answer_correct = await determine_if_answer_is_correct(
        model, final_answer, scenario
    )
    rubric.sources_correct = scenario.message_ids[0] in final_sources
```

**逻辑：**
- ✅ 如果答案是 "I don't know" → 不调用 GPT-4o judger
  - 因为已经明确表示不知道，不需要判断正确性
  - `rubric.returned_i_dont_know = True`
  - `rubric.attempted_answer = False`

- ✅ 如果答案是具体内容 → 调用 GPT-4o judger
  - 需要判断答案是否与标准答案匹配
  - `rubric.attempted_answer = True`
  - 调用 `determine_if_answer_is_correct()` 

**何时会看到 GPT-4o 调用：**

只有当模型返回具体答案时，例如：
```json
{
  "answer": "The video conference with Avi from Mars Corp. is scheduled for July 23, 2000 at 2:00 PM",
  "sources": ["<12345.67890@enron.com>"]
}
```

此时才会调用 GPT-4o 来判断这个答案是否正确。

---

## 总结

| 问题 | 状态 | 说明 |
|------|------|------|
| 1. 数据库查询是否执行？ | ✅ 执行了 | 返回空结果，可能是数据不存在或搜索条件太严格 |
| 2. 结果是否传递到后续？ | ✅ 传递了 | 但模型没有调整策略，重复使用相同参数 |
| 3. 为什么没有 GPT-4o 调用？ | ✅ 正常 | 返回 "I don't know" 时不需要 judger |

---

## 建议的改进方向

### 1. 优化 System Prompt

在 `rollout.py` 中添加更详细的搜索指导：

```python
system_prompt = textwrap.dedent(f"""\
    You are an email search agent. You are given a user query and a list of tools you can use to search the user's email.
    
    Search Strategy:
    - Start with specific keywords and filters
    - If you get empty results, try:
      * Remove sender/recipient filters (from_addr, to_addr)
      * Expand the date range
      * Use fewer or different keywords
      * Try alternative phrasings
    - You have up to {model.config.max_turns} turns, use them wisely
    
    User's email address is {scenario.inbox_address}
    Today's date is {scenario.query_date}
""")
```

### 2. 调试数据库内容

运行以下查询验证测试数据：

```bash
# 进入 art-e 目录
cd examples/art-e

# 检查数据库
sqlite3 data/enron_emails.db "
SELECT 
    e.message_id, 
    e.date, 
    e.subject,
    e.from_address
FROM emails e
WHERE (e.from_address = 'greg.whalley@enron.com' 
   OR EXISTS (
       SELECT 1 FROM recipients r 
       WHERE r.recipient_address = 'greg.whalley@enron.com' 
       AND r.email_id = e.id
   ))
AND e.date >= '2000-07-20 00:00:00' 
AND e.date < '2000-07-25 00:00:00'
LIMIT 10;
"
```

### 3. 放宽工具调用的默认参数

修改模型的工具调用逻辑，不要同时指定 from_addr 和 to_addr 为同一个人。

### 4. 测试其他样本

```bash
# 测试多个样本看是否有相同问题
python -m art_e.evaluate.benchmark_qwen3 -v -l 5
```

### 5. 添加中间步骤日志

在 `email_search_tools.py` 中启用 DEBUG 日志：

```python
logging.basicConfig(
    level=logging.DEBUG,  # 改为 DEBUG
    format="%(asctime)s - %(levelname)s - %(message)s"
)
```

这样可以看到实际执行的 SQL 语句和参数。

