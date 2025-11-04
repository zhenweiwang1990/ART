# 详细日志输出示例

运行 `python -m art_e.evaluate.benchmark_qwen3` 后，你会看到详细的日志输出。

## 输出格式说明

### 1. 初始化信息
```
🚀🚀🚀... (装饰线)
开始 Qwen3 模型评估 - 详细日志模式
🚀🚀🚀...

说明:
  1. 每次 Qwen3 调用会显示 🤖 标记
  2. GPT-4o judger 调用会显示 🧑‍⚖️ 标记
  3. 输入消息包含: system prompt, user query, tool responses
  4. 输出包含: 模型的回复和工具调用

📋 模型配置:
  - 名称: qwen3-ollama
  - 连接: http://localhost:11434
  - LiteLLM 模型: ollama/qwen3-32k
  - 使用工具: True
  - 最大轮数: 30
```

### 2. Qwen3 模型调用 (每轮会话)

每次 Qwen3 被调用时会显示：

```
================================================================================
🤖 QWEN3 模型调用
================================================================================

📥 模型: ollama/qwen3-32k
📥 Base URL: http://localhost:11434

📨 输入消息 (3 条):
--------------------------------------------------------------------------------

[消息 1] Role: system
Content: You are an email search agent. You are given a user query and a list 
of tools you can use to search the user's email...

[消息 2] Role: user
Content: Who sent me the email about the quarterly report?

[消息 3] Role: tool
Tool Call ID: call_abc123
Content: {"results": [...]}

⚙️ 其他参数:
  - max_tokens: 4096
  - tools: 3 个工具
  - tool_choice: required

📤 响应:
--------------------------------------------------------------------------------
Role: assistant
Tool Calls: [
  {
    "id": "call_xyz789",
    "type": "function",
    "function": {
      "name": "search_emails",
      "arguments": "{\"query\": \"quarterly report\"}"
    }
  }
]

📊 Token 使用:
  - Prompt tokens: 1234
  - Completion tokens: 56
  - Total tokens: 1290
================================================================================
```

### 3. GPT-4o Judger 调用

当需要判断答案是否正确时：

```
================================================================================
🧑‍⚖️ GPT-4o JUDGER 调用
================================================================================

📥 模型: gpt-4o
📥 Base URL: https://api.openai.com/v1

📨 输入消息 (2 条):
--------------------------------------------------------------------------------

[消息 1] Role: system
Content: You will be given an question and two different answers to the question, 
the correct answer and the answer given by an AI. Your job is to determine if the 
answer given by the AI is correct...

[消息 2] Role: user
Content: Question: Who sent me the email about the quarterly report?
Correct answer: John Smith
AI answer: John Smith from accounting

⚙️ 其他参数:
  - temperature: 0
  - max_tokens: 2

📤 响应:
--------------------------------------------------------------------------------
Role: assistant
Content: True

📊 Token 使用:
  - Prompt tokens: 123
  - Completion tokens: 1
  - Total tokens: 124
================================================================================
```

### 4. 最终评估结果

```
📊📊📊... (装饰线)
最终评估结果:
📊📊📊...

┌─────────────────┬────────┐
│ answer_correct  │ 1.0    │
│ sources_correct │ 1.0    │
│ num_turns       │ 3.0    │
│ ...             │ ...    │
└─────────────────┴────────┘
```

## 日志内容说明

### Qwen3 输入日志包含:
- **System prompt**: 告诉模型它的角色和任务
- **User query**: 用户的问题
- **Tool responses**: 工具执行的结果（搜索邮件、读取邮件等）
- **可用工具**: 3个工具（search_emails, read_email, return_final_answer）
- **参数配置**: max_tokens, tool_choice 等

### Qwen3 输出日志包含:
- **Tool calls**: 模型决定调用哪个工具以及参数
- **Content**: 如果有文本回复
- **Token 统计**: prompt tokens, completion tokens

### GPT-4o Judger 输入日志包含:
- **System prompt**: 判断指令
- **User content**: 
  - 原始问题
  - 正确答案
  - AI 给出的答案

### GPT-4o Judger 输出日志包含:
- **Content**: "True" 或 "False" (答案是否正确)
- **Token 统计**: 通常很少 (1-2 tokens)

## 使用技巧

1. **查看完整对话流程**: 按照 🤖 标记追踪 Qwen3 的多轮对话
2. **验证工具调用**: 检查 Tool Calls 部分确认模型正确使用工具
3. **分析 token 使用**: 查看每次调用的 token 消耗
4. **调试答案判断**: 通过 🧑‍⚖️ 标记查看 GPT-4o 如何判断答案正确性
5. **追踪错误**: 如果评估失败，详细日志能帮你定位问题所在

## 示例场景

一个完整的评估场景通常包括:
1. 初始化 (1次)
2. Qwen3 第1轮: 搜索邮件 (🤖)
3. Qwen3 第2轮: 读取邮件 (🤖)
4. Qwen3 第3轮: 返回答案 (🤖)
5. GPT-4o 判断答案 (🧑‍⚖️)
6. 显示最终结果 (📊)

每个步骤的输入输出都会完整展示，方便你分析模型行为！

