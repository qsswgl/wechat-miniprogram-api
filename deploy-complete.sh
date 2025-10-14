#!/bin/bash

echo "🚀 开始部署WeChat API修复版本..."
echo "================================"

# 1. 停止并删除现有容器
echo "📦 停止现有wechat-api容器..."
if docker stop wechat-api 2>/dev/null; then
    echo "✅ 容器已停止"
else
    echo "⚠️  容器未运行或不存在"
fi

echo "🗑️  删除现有容器..."
if docker rm wechat-api 2>/dev/null; then
    echo "✅ 容器已删除"
else
    echo "⚠️  容器不存在"
fi

# 2. 拉取最新镜像
echo "📥 拉取最新修复版本镜像..."
docker pull 43.138.35.183:5000/wechat-api-net8:alpine-musl-ssl-swagger-port-fixed

if [ $? -eq 0 ]; then
    echo "✅ 镜像拉取成功"
else
    echo "❌ 镜像拉取失败"
    exit 1
fi

# 3. 启动新容器
echo "🚀 启动新容器（端口配置已修复）..."
docker run -d \
  --name wechat-api \
  --restart unless-stopped \
  -p 8090:8090 \
  -p 8091:8091 \
  -p 8092:8092 \
  -e DOTNET_RUNNING_IN_CONTAINER=true \
  -e ASPNETCORE_ENVIRONMENT=Production \
  43.138.35.183:5000/wechat-api-net8:alpine-musl-ssl-swagger-port-fixed

if [ $? -eq 0 ]; then
    echo "✅ 新容器启动成功"
else
    echo "❌ 容器启动失败"
    exit 1
fi

# 4. 等待容器启动
echo "⏳ 等待容器完全启动..."
sleep 10

# 5. 检查容器状态
echo "📊 检查容器状态..."
docker ps --filter "name=wechat-api" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# 6. 检查容器日志
echo ""
echo "📋 最新日志："
docker logs wechat-api --tail 20

echo ""
echo "🎉 部署完成！"
echo "================================"
echo "访问地址："
echo "📖 Swagger文档:  http://43.138.35.183:8090/swagger"
echo "🔒 HTTPS Swagger: https://43.138.35.183:8091/swagger"
echo ""
echo "🔍 健康检查："
echo "   http://43.138.35.183:8090/api/health"
echo "   http://43.138.35.183:8090/api/health/info"
echo ""
echo "🔧 API端点："
echo "   http://43.138.35.183:8090/api/WeChat/CreateMiniProgramCode"
echo ""
echo "🧪 测试建议："
echo "1. 先访问健康检查端点验证服务是否正常"
echo "2. 然后访问Swagger文档查看API接口"
echo "3. 最后测试实际API功能"
echo ""
echo "如果还有问题，请查看容器日志："
echo "docker logs wechat-api -f"