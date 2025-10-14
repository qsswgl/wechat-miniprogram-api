#!/bin/bash
echo "快速修复 WeChat API 容器端口映射问题"

echo "停止当前容器 wechat-api..."
docker stop wechat-api

echo "删除当前容器..."
docker rm wechat-api

echo "重新创建容器（修复端口映射）..."
docker run -d \
  --name wechat-api \
  --restart unless-stopped \
  -p 8080:8080 \
  -p 8081:8081 \
  -p 8082:8082 \
  -v /root/certificates:/app/certificates:ro \
  -e ASPNETCORE_ENVIRONMENT=Production \
  43.138.35.183:5000/wechat-api-net8:alpine-musl

echo "等待启动..."
sleep 10

echo "检查新容器状态:"
docker ps | grep wechat-api

echo "检查应用启动日志:"
docker logs wechat-api | tail -8

echo ""
echo "测试API访问:"
echo "测试HTTP根路径..."
curl -s -o /dev/null -w "HTTP根路径: %{http_code}\n" http://localhost:8080/

echo "测试Swagger文档..."
curl -s -o /dev/null -w "Swagger文档: %{http_code}\n" http://localhost:8080/swagger/index.html

echo "测试HTTPS访问..."
curl -k -s -o /dev/null -w "HTTPS访问: %{http_code}\n" https://localhost:8081/

echo ""
echo "修复完成! 访问地址:"
echo "HTTP: http://$(curl -s ifconfig.me 2>/dev/null):8080"
echo "HTTPS: https://$(curl -s ifconfig.me 2>/dev/null):8081"
echo "Swagger: http://$(curl -s ifconfig.me 2>/dev/null):8080/swagger"