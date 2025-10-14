#!/bin/bash
# 停止并删除现有容器
docker stop wechat-api || true
docker rm wechat-api || true

# 拉取最新镜像
docker pull 43.138.35.183:5000/wechat-api-net8:alpine-musl-ssl-swagger-port-fixed

# 启动新容器（端口配置已修复）
docker run -d \
  --name wechat-api \
  --restart unless-stopped \
  -p 8090:8090 \
  -p 8091:8091 \
  -p 8092:8092 \
  -e DOTNET_RUNNING_IN_CONTAINER=true \
  -e ASPNETCORE_ENVIRONMENT=Production \
  43.138.35.183:5000/wechat-api-net8:alpine-musl-ssl-swagger-port-fixed

echo "Docker容器已启动，端口配置已修复！"
echo "访问地址："
echo "HTTP Swagger:  http://43.138.35.183:8090/swagger"
echo "HTTPS Swagger: https://43.138.35.183:8091/swagger"
echo ""
echo "健康检查："
echo "http://43.138.35.183:8090/api/health"
echo "http://43.138.35.183:8090/api/health/info"
echo ""
echo "API端点："
echo "WeChat API: http://43.138.35.183:8090/api/WeChat/CreateMiniProgramCode"