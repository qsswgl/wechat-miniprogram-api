#!/bin/bash

# 部署修复JSON序列化问题的新镜像
echo "开始部署JSON序列化修复版本..."

# 停止并删除现有容器
echo "停止现有容器..."
docker stop wechat-api || true
docker rm wechat-api || true

# 拉取新镜像
echo "拉取新镜像..."
docker pull 43.138.35.183:5000/wechat-api-net8:alpine-musl-json-fixed

# 运行新容器
echo "启动新容器..."
docker run -d \
  --name wechat-api \
  --restart unless-stopped \
  -p 8090:8080 \
  -p 8091:8081 \
  -p 8092:8082 \
  -v /etc/localtime:/etc/localtime:ro \
  --memory=512m \
  --cpus="1" \
  43.138.35.183:5000/wechat-api-net8:alpine-musl-json-fixed

# 等待容器启动
echo "等待容器启动..."
sleep 10

# 检查容器状态
echo "检查容器状态:"
docker ps | grep wechat-api

# 检查容器日志
echo "容器启动日志:"
docker logs wechat-api --tail 20

echo "部署完成! 访问地址:"
echo "HTTP: http://43.138.35.183:8090/swagger"
echo "HTTPS: https://43.138.35.183:8091/swagger"
echo "HTTPS2: https://43.138.35.183:8092/swagger"