#!/bin/bash

# 实时监控 Docker 构建进度

BUILD_LOG="build.log"

echo "🔍 监控 Docker 构建进度"
echo "================================"
echo ""

if [ ! -f "$BUILD_LOG" ]; then
    echo "❌ 找不到构建日志文件: $BUILD_LOG"
    echo "请确保构建正在运行..."
    exit 1
fi

echo "📊 当前构建步骤:"
echo ""

# 显示最新的进度
tail -50 "$BUILD_LOG" | grep -E "^#[0-9]|DONE|ERROR|Successfully|Downloading|Installing" | tail -20

echo ""
echo "================================"
echo ""
echo "💡 使用提示:"
echo "  - 实时跟踪: tail -f $BUILD_LOG"
echo "  - 查看错误: grep ERROR $BUILD_LOG"
echo "  - 查看完整日志: cat $BUILD_LOG"
echo ""
echo "⏱️  预计总时间: 20-30 分钟"
echo "📦 预计镜像大小: 15-20 GB"
echo ""

