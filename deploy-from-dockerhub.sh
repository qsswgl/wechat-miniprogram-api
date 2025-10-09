#!/bin/bash
# QSGL WeChat API - 从Docker Hub部署脚本

echo "===== 从Docker Hub部署QSGL WeChat API ====="
echo

# 检查Docker是否安装
if ! command -v docker &> /dev/null; then
    echo "[错误] Docker未安装，请先安装Docker"
    echo "Ubuntu安装命令: sudo apt update && sudo apt install docker.io docker-compose"
    exit 1
fi

# 检查Docker是否运行
if ! docker info &> /dev/null; then
    echo "[错误] Docker未运行，请启动Docker服务"
    echo "启动命令: sudo systemctl start docker"
    exit 1
fi

echo "[√] Docker环境检查通过"

# 设置变量
IMAGE_NAME="qsswgl/wechat-api:latest"
CONTAINER_NAME="qsgl-wechat-api"

# 停止现有容器
echo "停止现有容器..."
docker stop $CONTAINER_NAME 2>/dev/null || true
docker rm $CONTAINER_NAME 2>/dev/null || true

# 拉取最新镜像
echo "拉取最新镜像..."
docker pull $IMAGE_NAME

if [ $? -ne 0 ]; then
    echo "[错误] 镜像拉取失败"
    exit 1
fi

echo "[√] 镜像拉取成功"

# 创建必要目录
mkdir -p certificates uploadall

# 启动容器 - 仅HTTP模式
echo "启动容器（HTTP模式）..."
docker run -d \
    --name $CONTAINER_NAME \
    -p 8080:8080 \
    -v $(pwd)/uploadall:/app/wwwroot/uploadall \
    -e ASPNETCORE_ENVIRONMENT=Production \
    --restart unless-stopped \
    $IMAGE_NAME

if [ $? -ne 0 ]; then
    echo "[错误] 容器启动失败"
    exit 1
fi

# 等待启动
echo "等待服务启动..."
sleep 10

# 检查容器状态
if docker ps | grep -q $CONTAINER_NAME; then
    echo "[√] 容器启动成功"
    echo
    echo "===== 部署完成 ====="
    echo "HTTP访问: http://$(curl -s ifconfig.me):8080/swagger"
    echo "本地访问: http://localhost:8080/swagger"
    echo
    echo "查看日志: docker logs $CONTAINER_NAME"
    echo "停止服务: docker stop $CONTAINER_NAME"
    echo "重启服务: docker restart $CONTAINER_NAME"
else
    echo "[错误] 容器启动失败，查看日志:"
    docker logs $CONTAINER_NAME
    exit 1
fi