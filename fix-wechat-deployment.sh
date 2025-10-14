#!/bin/bash
echo "🔧 解决WeChat API部署冲突"
echo "========================"

echo ""
echo "📊 当前状态:"
echo "- wechat-api容器存在但未运行 (Created状态)"
echo "- dbaccess-api占用8080端口"
echo "- 需要清理并使用备用端口"

echo ""
echo "🗑️ [1] 清理已存在的wechat-api容器..."
docker rm wechat-api
echo "✅ 已删除wechat-api容器"

echo ""
echo "🚀 [2] 使用备用端口重新部署..."
docker run -d \
  --name wechat-api \
  --restart unless-stopped \
  -p 8090:8080 \
  -p 8091:8081 \
  -p 8092:8082 \
  -e ASPNETCORE_ENVIRONMENT=Production \
  43.138.35.183:5000/wechat-api-net8:alpine-musl-ssl

echo "✅ 容器已启动"

echo ""
echo "⏳ [3] 等待容器启动..."
sleep 15

echo ""
echo "📋 [4] 检查容器状态..."
docker ps | grep wechat-api

echo ""
echo "📜 [5] 查看启动日志..."
docker logs wechat-api | tail -10

echo ""
echo "🔗 [6] 测试API访问..."
echo "测试HTTP访问:"
curl -s -o /dev/null -w "HTTP状态码: %{http_code}\n" http://localhost:8090/ || echo "HTTP访问失败"

echo "测试Swagger:"
curl -s -o /dev/null -w "Swagger状态码: %{http_code}\n" http://localhost:8090/swagger/index.html || echo "Swagger访问失败"

echo "测试HTTPS访问:"
curl -k -s -o /dev/null -w "HTTPS状态码: %{http_code}\n" https://localhost:8091/ || echo "HTTPS访问失败"

echo ""
echo "🌐 访问信息:"
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || echo "your-server-ip")
echo "HTTP API: http://$SERVER_IP:8090"
echo "HTTPS API: https://$SERVER_IP:8091"
echo "Swagger文档: http://$SERVER_IP:8090/swagger"
echo "HTTPS Swagger: https://$SERVER_IP:8091/swagger"

echo ""
echo "✅ 部署完成!"