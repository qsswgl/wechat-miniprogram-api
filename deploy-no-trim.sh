#!/bin/bash
# 🚀 部署WeChat API - 禁用Trim版本（修复Swagger"No operations"问题）

echo "🔧 停止现有容器..."
docker stop wechat-api || true
docker rm wechat-api || true

echo "📥 拉取修复版本镜像（禁用PublishTrimmed）..."
docker pull 43.138.35.183:5000/wechat-api-net8:alpine-musl-no-trim

echo "🚀 启动新容器（控制器已完整保留）..."
docker run -d \
  --name wechat-api \
  --restart unless-stopped \
  -p 8090:8090 \
  -p 8091:8091 \
  -p 8092:8092 \
  -e DOTNET_RUNNING_IN_CONTAINER=true \
  -e ASPNETCORE_ENVIRONMENT=Production \
  43.138.35.183:5000/wechat-api-net8:alpine-musl-no-trim

echo "⏳ 等待容器启动..."
sleep 8

echo "📊 检查容器状态..."
docker ps --filter "name=wechat-api" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "🎉 部署完成！"
echo "================================"
echo "🔍 问题修复："
echo "   ✅ SSL证书路径已修复"
echo "   ✅ 端口配置已修复"  
echo "   ✅ 禁用PublishTrimmed保护控制器"
echo ""
echo "🌐 访问地址："
echo "   HTTP Swagger:  http://43.138.35.183:8090/swagger"
echo "   HTTPS Swagger: https://43.138.35.183:8091/swagger"
echo "   HTTP/2 Swagger: https://43.138.35.183:8092/swagger"
echo ""
echo "🔍 健康检查："
echo "   http://43.138.35.183:8090/api/health"
echo "   http://43.138.35.183:8090/api/health/info"
echo ""
echo "🔧 API端点："
echo "   http://43.138.35.183:8090/api/WeChat/CreateMiniProgramCode"
echo ""
echo "📋 如需查看日志："
echo "   docker logs wechat-api -f"