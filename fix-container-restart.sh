#!/bin/bash
# QSGL WeChat API 修复后重新部署

echo "=== 修复Docker容器重启问题 ==="

# 1. 停止所有容器
echo "停止现有容器..."
docker-compose down
docker stop qsgl-wechat-api 2>/dev/null || true
docker rm qsgl-wechat-api 2>/dev/null || true

# 2. 清理Docker
echo "清理Docker环境..."
docker system prune -f
docker builder prune -f

# 3. 重新构建
echo "重新构建镜像..."
docker-compose build --no-cache --pull

# 4. 先测试HTTP端口
echo "测试基础HTTP启动..."
docker run --rm -p 8080:8080 --name test-container \
  -e ASPNETCORE_ENVIRONMENT=Production \
  wechatminiprogramapi-wechat-api &

# 等待5秒
sleep 5

# 检查容器状态
if docker ps | grep -q test-container; then
    echo "✓ HTTP模式测试成功"
    docker stop test-container
else
    echo "✗ HTTP模式测试失败，查看日志："
    docker logs test-container 2>/dev/null || echo "无法获取日志"
    exit 1
fi

# 5. 正式启动
echo "启动服务..."
docker-compose up -d

# 6. 等待启动
sleep 10

# 7. 检查状态
echo "检查容器状态..."
docker-compose ps
docker-compose logs --tail=20

echo ""
echo "=== 部署完成 ==="
echo "HTTP访问: http://123.57.93.200:8080/swagger"
echo ""
echo "如果仍有问题，执行："
echo "docker-compose logs --follow"