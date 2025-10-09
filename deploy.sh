#!/bin/bash

# QSGL WeChat API Docker 部署脚本

echo "开始构建和部署 QSGL WeChat API Docker 容器..."

# 停止现有容器
echo "停止现有容器..."
docker-compose down

# 构建镜像
echo "构建 Docker 镜像..."
docker-compose build --no-cache

# 启动服务
echo "启动服务..."
docker-compose up -d

# 检查服务状态
echo "检查服务状态..."
sleep 5
docker-compose ps

echo "部署完成！"
echo ""
echo "服务访问地址："
echo "HTTP:  http://localhost:8080/swagger"
echo "HTTPS: https://localhost:8081/swagger"
echo "HTTP/3: https://localhost:8082/swagger"
echo "HTTPS兼容: https://localhost:8083/swagger"
echo ""
echo "查看日志: docker-compose logs -f"
echo "停止服务: docker-compose down"