#!/usr/bin/env python3
"""
测试 vLLM 服务器是否正常运行

使用方法:
    python scripts/test_vllm_server.py
"""

import requests
import json
import sys

def test_vllm_server(base_url: str = "http://localhost:8000"):
    """测试 vLLM 服务器连接和基本功能"""
    
    print(f"测试 vLLM 服务器: {base_url}")
    print("=" * 50)
    
    # 测试 1: 检查服务器是否运行
    try:
        response = requests.get(f"{base_url}/v1/models", timeout=5)
        if response.status_code == 200:
            models = response.json()
            print("✓ 服务器运行正常")
            print(f"  可用模型: {json.dumps(models, indent=2, ensure_ascii=False)}")
        else:
            print(f"✗ 服务器响应异常: {response.status_code}")
            return False
    except requests.exceptions.ConnectionError:
        print(f"✗ 无法连接到服务器 {base_url}")
        print("  请确保 vLLM 服务器已启动")
        print("  启动命令: ./scripts/run_vllm_qwen3.sh")
        return False
    except Exception as e:
        print(f"✗ 连接错误: {e}")
        return False
    
    print()
    
    # 测试 2: 发送简单的补全请求
    try:
        print("测试文本生成...")
        completion_data = {
            "model": models["data"][0]["id"],  # 使用第一个可用模型
            "messages": [
                {"role": "user", "content": "你好，请用一句话介绍你自己。"}
            ],
            "max_tokens": 100,
            "temperature": 0.7
        }
        
        response = requests.post(
            f"{base_url}/v1/chat/completions",
            json=completion_data,
            timeout=30
        )
        
        if response.status_code == 200:
            result = response.json()
            content = result["choices"][0]["message"]["content"]
            print("✓ 文本生成成功")
            print(f"  回复: {content}")
        else:
            print(f"✗ 生成失败: {response.status_code}")
            print(f"  错误: {response.text}")
            return False
            
    except Exception as e:
        print(f"✗ 生成测试失败: {e}")
        return False
    
    print()
    
    # 测试 3: 测试工具调用（如果支持）
    try:
        print("测试工具调用能力...")
        tool_data = {
            "model": models["data"][0]["id"],
            "messages": [
                {"role": "user", "content": "北京今天天气怎么样？"}
            ],
            "tools": [
                {
                    "type": "function",
                    "function": {
                        "name": "get_weather",
                        "description": "获取指定城市的天气信息",
                        "parameters": {
                            "type": "object",
                            "properties": {
                                "city": {
                                    "type": "string",
                                    "description": "城市名称"
                                }
                            },
                            "required": ["city"]
                        }
                    }
                }
            ],
            "max_tokens": 100
        }
        
        response = requests.post(
            f"{base_url}/v1/chat/completions",
            json=tool_data,
            timeout=30
        )
        
        if response.status_code == 200:
            result = response.json()
            choice = result["choices"][0]
            if "tool_calls" in choice["message"]:
                print("✓ 工具调用支持正常")
                print(f"  工具调用: {json.dumps(choice['message']['tool_calls'], indent=2, ensure_ascii=False)}")
            else:
                print("⚠ 模型未使用工具（可能不支持或不需要）")
                print(f"  回复: {choice['message']['content']}")
        else:
            print(f"⚠ 工具调用测试失败（可能不支持）: {response.status_code}")
            
    except Exception as e:
        print(f"⚠ 工具调用测试出错（可能不支持）: {e}")
    
    print()
    print("=" * 50)
    print("✓ 所有基础测试通过！")
    print("你现在可以运行: python -m art_e.evaluate.benchmark_qwen3")
    return True

if __name__ == "__main__":
    success = test_vllm_server()
    sys.exit(0 if success else 1)

