#!/bin/bash
# 停止并删除现有容器
docker stop wechat-api || true
docker rm wechat-api || true

# 拉取最新镜像
docker pull 43.138.35.183:5000/wechat-api-net8:alpine-musl-ssl-swagger-fixed

# 启动新容器
docker run -d \
  --name wechat-api \
  --restart unless-stopped \
  -p 8090:8090 \
  -p 8091:8091 \
  -p 8092:8092 \
  -e DOTNET_RUNNING_IN_CONTAINER=true \
  -e ASPNETCORE_ENVIRONMENT=Production \
  43.138.35.183:5000/wechat-api-net8:alpine-musl-ssl-swagger-fixed

echo "Docker容器已启动，访问地址："
echo "HTTP:  http://43.138.35.183:8090/swagger"
echo "HTTPS: https://43.138.35.183:8091/swagger"
echo ""
echo "健康检查："
echo "http://43.138.35.183:8090/api/health"
echo "http://43.138.35.183:8090/api/health/info"