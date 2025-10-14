#!/bin/bash
# WeChat API SSL版本快速部署

echo "🚀 WeChat API SSL版本快速部署"
echo "================================"

# 停止旧容器
docker stop wechat-api 2>/dev/null
docker rm wechat-api 2>/dev/null

# 拉取并运行新的SSL版本
echo "📥 拉取SSL版本镜像..."
docker pull 43.138.35.183:5000/wechat-api-net8:alpine-musl-ssl

echo "🔄 启动新容器..."
docker run -d \
  --name wechat-api \
  --restart unless-stopped \
  -p 8080:8080 \
  -p 8081:8081 \
  -p 8082:8082 \
  -e ASPNETCORE_ENVIRONMENT=Production \
  43.138.35.183:5000/wechat-api-net8:alpine-musl-ssl

echo "⏳ 等待启动..."
sleep 15

echo "📊 检查状态:"
docker ps | grep wechat-api
echo ""
echo "📋 应用日志:"
docker logs wechat-api | tail -5
echo ""
echo "🔗 测试访问:"
curl -s -o /dev/null -w "HTTP: %{http_code}\n" http://localhost:8080/
curl -k -s -o /dev/null -w "HTTPS: %{http_code}\n" https://localhost:8081/
echo ""
echo "✅ 部署完成! 访问: http://$(curl -s ifconfig.me):8080"