"""
使用 OpenAI API 评估（GPT-4o）

使用方法:
1. 设置环境变量: export OPENAI_API_KEY=your_key
2. 运行: python -m art_e.evaluate.benchmark_openai
"""

import art
from art_e.evaluate.benchmark import benchmark_model
from art_e.project_types import ProjectPolicyConfig
import asyncio
import os
from dotenv import load_dotenv

load_dotenv()

async def main():
    openai_key = os.getenv("OPENAI_API_KEY")
    if not openai_key:
        print("错误: 未找到 OPENAI_API_KEY 环境变量")
        return
    
    model = art.Model(
        name="gpt4o-baseline",
        project="email_agent",
        config=ProjectPolicyConfig(
            litellm_model_name="gpt-4o",
            use_tools=True,
            max_turns=30,
        ),
        inference_api_key=openai_key,
        inference_base_url="https://api.openai.com/v1",
    )
    
    print(f"开始评估 {model.name}...")
    print(f"模型: GPT-4o")
    print("-" * 50)
    
    results = await benchmark_model(model, limit=10, swallow_exceptions=False)
    
    print("\n" + "=" * 50)
    print("评估结果:")
    print("=" * 50)
    print(results)
    
    return results

if __name__ == "__main__":
    results = asyncio.run(main())

