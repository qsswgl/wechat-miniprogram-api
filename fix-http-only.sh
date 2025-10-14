#!/bin/bash
echo "===== 临时解决方案：仅启用HTTP访问 ====="

# 停止当前崩溃的容器
echo "[1] 停止崩溃的容器..."
docker stop wechat-api 2>/dev/null || true
docker rm wechat-api 2>/dev/null || true

# 创建仅HTTP的容器
echo "[2] 创建HTTP-only容器..."
docker run -d \
  --name wechat-api \
  --restart unless-stopped \
  -p 8080:8080 \
  -e ASPNETCORE_ENVIRONMENT=Production \
  -e ASPNETCORE_URLS="http://+:8080" \
  43.138.35.183:5000/wechat-api-net8:alpine-musl

echo "等待启动..."
sleep 10

echo "[3] 检查容器状态..."
docker ps | grep wechat-api

echo "[4] 检查应用日志..."
docker logs wechat-api | tail -8

echo "[5] 测试HTTP访问..."
sleep 2
curl -s -o /dev/null -w "HTTP状态: %{http_code}\n" http://localhost:8080/ || echo "HTTP访问失败"
curl -s -o /dev/null -w "Swagger状态: %{http_code}\n" http://localhost:8080/swagger/index.html || echo "Swagger访问失败"

echo ""
echo "✅ 临时解决方案完成!"
echo "HTTP API: http://$(curl -s ifconfig.me 2>/dev/null):8080"
echo "Swagger: http://$(curl -s ifconfig.me 2>/dev/null):8080/swagger"
echo ""
echo "💡 要启用HTTPS支持，请："
echo "1. 上传证书文件到 /root/certificates/qsgl.net.pfx"
echo "2. 重新运行完整的部署脚本"