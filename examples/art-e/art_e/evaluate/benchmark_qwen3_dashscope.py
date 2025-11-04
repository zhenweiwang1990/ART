"""
Qwen3 模型评估脚本 - 使用 DashScope (阿里云) API

使用方法:
1. 获取 API Key: https://dashscope.console.aliyun.com/apiKey
2. 设置环境变量: export DASHSCOPE_API_KEY=your_key
3. 运行此脚本: python -m art_e.evaluate.benchmark_qwen3_dashscope
"""

import art
from art_e.evaluate.benchmark import benchmark_model
from art_e.project_types import ProjectPolicyConfig
import asyncio
import os
from dotenv import load_dotenv

load_dotenv()

async def main():
    # 检查 API Key
    dashscope_key = os.getenv("DASHSCOPE_API_KEY")
    if not dashscope_key:
        print("错误: 未找到 DASHSCOPE_API_KEY 环境变量")
        print("请访问 https://dashscope.console.aliyun.com/apiKey 获取 API Key")
        print("然后运行: export DASHSCOPE_API_KEY=your_key")
        return
    
    # 使用 DashScope API（阿里云官方 Qwen API）
    # 完整支持工具调用，无需本地部署
    model = art.Model(
        name="qwen3-dashscope",
        project="email_agent",
        config=ProjectPolicyConfig(
            # DashScope 支持的 Qwen 模型
            # qwen-max: 最新最强模型（推荐）
            # qwen-plus: 性能平衡
            # qwen-turbo: 速度优先
            litellm_model_name="qwen/qwen-max",
            use_tools=True,  # ✓ 完整支持工具调用
            max_turns=30,
        ),
        inference_api_key=dashscope_key,
        inference_base_url="https://dashscope.aliyuncs.com/compatible-mode/v1",
    )
    
    print(f"开始评估 {model.name}...")
    print(f"API: DashScope (阿里云)")
    print(f"模型: {model.config.litellm_model_name}")
    print(f"工具调用: {'✓ 启用' if model.config.use_tools else '✗ 禁用'}")
    print("-" * 50)
    
    # 运行评估
    results = await benchmark_model(
        model, 
        limit=10,  # 云 API 有费用，先测试 10 个样本
        swallow_exceptions=False  # 显示错误以便调试
    )
    
    print("\n" + "=" * 50)
    print("评估结果:")
    print("=" * 50)
    print(results)
    
    print("\n提示: 增加 limit 参数可测试更多样本")
    print("例如: limit=100 (完整评估)")
    
    return results

if __name__ == "__main__":
    results = asyncio.run(main())

