#!/bin/bash

echo "🧹 清理重复文件和准备Docker构建..."

# 删除可能导致冲突的重复文件和目录
if [ -d "docker-deploy" ]; then
    echo "删除 docker-deploy 目录..."
    rm -rf docker-deploy
fi

if [ -f "qsgl-api-docker.zip" ]; then
    echo "删除旧的zip包..."
    rm -f qsgl-api-docker.zip
fi

# 删除可能的重复Program.cs文件
find . -name "Program.cs" -not -path "./Program.cs" -delete 2>/dev/null || true

# 清理Docker缓存
echo "清理Docker构建缓存..."
docker system prune -f

echo "✅ 清理完成！现在可以重新构建了。"