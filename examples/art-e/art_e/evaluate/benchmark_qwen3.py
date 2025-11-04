"""
Qwen3 模型评估脚本

使用方法:
1. 首先启动 vLLM 服务器（见 scripts/run_vllm_qwen3.sh）
2. 运行此脚本: python -m art_e.evaluate.benchmark_qwen3 [--verbose]

参数:
  --verbose, -v    启用详细日志，打印所有输入输出（默认：关闭）
  --limit N        测试样本数量（默认：1）
"""

import os
import sys
import json
import argparse
import asyncio
from dotenv import load_dotenv

load_dotenv()

# 必须在导入 litellm 和其他使用 litellm 的模块之前，先获取 verbose 参数
# 这样才能在导入时就设置好日志包装
def _should_enable_verbose():
    """检查是否应该启用详细日志"""
    return '--verbose' in sys.argv or '-v' in sys.argv

# 导入 litellm（必须在其他模块之前）
import litellm

# 全局变量，用于存储原始函数
_original_acompletion = None
_verbose_enabled = False

# 启用详细日志
def setup_detailed_logging(enabled=True):
    """设置详细的日志输出，包括输入输出"""
    global _original_acompletion, _verbose_enabled
    
    if not enabled or _verbose_enabled:
        # 如果不启用详细日志，或者已经启用过，直接返回
        return
    
    _verbose_enabled = True
    
    # 保存原始函数的引用
    _original_acompletion = litellm.acompletion
    
    async def logged_acompletion(*args, **kwargs):
        """包装 acompletion 来记录输入输出"""
        model = kwargs.get('model', 'unknown')
        messages = kwargs.get('messages', [])
        
        # 判断是 Qwen3 还是 GPT-4o
        if 'gpt-4o' in model:
            print("\n" + "="*80)
            print("🧑‍⚖️ GPT-4o JUDGER 调用")
            print("="*80)
        else:
            print("\n" + "="*80)
            print("🤖 QWEN3 模型调用")
            print("="*80)
        
        # 打印输入
        print(f"\n📥 模型: {model}")
        print(f"📥 Base URL: {kwargs.get('base_url', 'N/A')}")
        print(f"\n📨 输入消息 ({len(messages)} 条):")
        print("-"*80)
        for i, msg in enumerate(messages):
            role = msg.get('role', 'unknown')
            content = msg.get('content', '')
            tool_calls = msg.get('tool_calls', None)
            tool_call_id = msg.get('tool_call_id', None)
            
            print(f"\n[消息 {i+1}] Role: {role}")
            if content:
                # 限制内容长度以便阅读
                if len(str(content)) > 500:
                    print(f"Content (前500字符): {str(content)[:500]}...")
                else:
                    print(f"Content: {content}")
            if tool_calls:
                print(f"Tool Calls: {json.dumps(tool_calls, indent=2, ensure_ascii=False)}")
            if tool_call_id:
                print(f"Tool Call ID: {tool_call_id}")
        
        # 打印其他参数
        print(f"\n⚙️ 其他参数:")
        for key in ['temperature', 'max_tokens', 'max_completion_tokens', 'tools', 'tool_choice']:
            if key in kwargs and kwargs[key] is not None:
                value = kwargs[key]
                if key == 'tools' and value:
                    print(f"  - {key}: {len(value)} 个工具")
                else:
                    print(f"  - {key}: {value}")
        
        # 调用原始函数
        response = await _original_acompletion(*args, **kwargs)
        
        # 打印输出
        print(f"\n📤 响应:")
        print("-"*80)
        if hasattr(response, 'choices') and response.choices:
            choice = response.choices[0]
            message = choice.message
            
            print(f"Role: {message.role}")
            if hasattr(message, 'content') and message.content:
                print(f"Content: {message.content}")
            if hasattr(message, 'tool_calls') and message.tool_calls:
                # 使用 model_dump 代替弃用的 dict 方法
                tool_calls_data = []
                for tc in message.tool_calls:
                    if hasattr(tc, 'model_dump'):
                        tool_calls_data.append(tc.model_dump())
                    elif hasattr(tc, 'dict'):
                        tool_calls_data.append(tc.dict())
                    else:
                        tool_calls_data.append(tc)
                print(f"Tool Calls: {json.dumps(tool_calls_data, indent=2, ensure_ascii=False)}")
        
        # 打印 token 使用情况
        if hasattr(response, 'usage') and response.usage:
            print(f"\n📊 Token 使用:")
            print(f"  - Prompt tokens: {response.usage.prompt_tokens}")
            print(f"  - Completion tokens: {response.usage.completion_tokens}")
            print(f"  - Total tokens: {response.usage.total_tokens if hasattr(response.usage, 'total_tokens') else 'N/A'}")
        
        print("="*80 + "\n")
        
        return response
    
    # 替换原始函数
    litellm.acompletion = logged_acompletion

# 在导入其他使用 litellm 的模块之前，先设置日志
# 这样才能捕获所有的 LLM 调用
_verbose_mode = _should_enable_verbose()
if _verbose_mode:
    print(f"\n🔧 调试信息: 正在启用详细日志...")
setup_detailed_logging(enabled=_verbose_mode)
if _verbose_mode:
    print(f"🔧 调试信息: litellm.acompletion 已被包装: {litellm.acompletion.__name__ if hasattr(litellm.acompletion, '__name__') else 'wrapped'}")
    print(f"🔧 调试信息: 现在开始导入其他模块...\n")

# 现在才导入其他模块（它们内部会使用 litellm）
import art
from art_e.evaluate.benchmark import benchmark_model
from art_e.project_types import ProjectPolicyConfig

async def main(verbose=False, limit=1):
    
    print("\n" + "🚀" * 40)
    if verbose:
        print("开始 Qwen3 模型评估 - 详细日志模式")
    else:
        print("开始 Qwen3 模型评估")
    print("🚀" * 40)
    
    if verbose:
        print("\n说明:")
        print("  1. 每次 Qwen3 调用会显示 🤖 标记")
        print("  2. GPT-4o judger 调用会显示 🧑‍⚖️ 标记")
        print("  3. 输入消息包含: system prompt, user query, tool responses")
        print("  4. 输出包含: 模型的回复和工具调用\n")
    
    # 配置本地部署的 Qwen3 模型
    # 方案 1: 使用 vLLM（Linux + NVIDIA GPU）
    # 确保 vLLM 服务器已在 http://localhost:8000 运行
    # os.environ["OPENAI_API_BASE"] = "http://localhost:8000/v1"
    # model = art.Model(
    #     name="qwen3-vllm",
    #     project="email_agent",
    #     config=ProjectPolicyConfig(
    #         litellm_model_name="openai/Qwen2.5-72B-Instruct",
    #         use_tools=True,
    #         max_turns=30,
    #     ),
    # )
    
    # 方案 2: 使用 Ollama（推荐用于 macOS）
    # 确保已运行: ollama serve
    os.environ["OLLAMA_API_BASE"] = "http://localhost:11434"
    model = art.Model(
        name="qwen3-ollama",
        project="email_agent",
        config=ProjectPolicyConfig(
            # Ollama 使用格式: ollama/<模型名>
            # 使用 qwen3-32k 以获得 32k 上下文窗口（而非默认的 4k）
            # litellm_model_name="ollama/qwen3-32k",
            litellm_model_name="ollama/qwen3:14b",
            use_tools=False,
            max_turns=30,
        ),
        # 设置推理连接信息（litellm 需要）
        inference_base_url="http://localhost:11434",
        inference_api_key="ollama",  # Ollama 不需要 key，但 litellm 可能需要非空值
    )
    
    print(f"\n📋 模型配置:")
    print(f"  - 名称: {model.name}")
    print(f"  - 连接: {os.environ.get('OLLAMA_API_BASE', os.environ.get('OPENAI_API_BASE', 'N/A'))}")
    print(f"  - LiteLLM 模型: {model.config.litellm_model_name}")
    print(f"  - 使用工具: {model.config.use_tools}")
    print(f"  - 最大轮数: {model.config.max_turns}")
    print("-" * 80)
    
    print("\n🎯 开始运行评估...")
    print(f"  - 测试样本数: {limit}")
    print(f"  - 详细日志: {'开启' if verbose else '关闭'}")
    print(f"  - 调试模式: 开启\n")
    
    # 运行评估
    # limit 控制测试样本数量
    # swallow_exceptions=False 显示错误（调试模式）
    results = await benchmark_model(
        model, 
        limit=limit,
        swallow_exceptions=False  # 显示错误以便调试
    )
    
    print("\n" + "📊" * 40)
    print("最终评估结果:")
    print("📊" * 40)
    print(results)
    print("\n")
    
    return results

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Qwen3 模型评估脚本",
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument(
        '--verbose', '-v',
        action='store_true',
        help='启用详细日志，打印所有 Qwen3 和 GPT-4o 的输入输出（默认：关闭）'
    )
    parser.add_argument(
        '--limit', '-l',
        type=int,
        default=1,
        help='测试样本数量（默认：1）'
    )
    
    args = parser.parse_args()
    results = asyncio.run(main(verbose=args.verbose, limit=args.limit))

