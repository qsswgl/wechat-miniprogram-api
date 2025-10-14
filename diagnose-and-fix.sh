#!/bin/bash
echo "===== WeChat API 容器诊断和修复工具 ====="
echo ""

# 检查当前容器状态
echo "[1] 检查容器运行状态..."
CONTAINER_ID=$(docker ps -q --filter "ancestor=43.138.35.183:5000/wechat-api-net8:alpine-musl")
if [ -z "$CONTAINER_ID" ]; then
    echo "❌ 没有找到运行中的 wechat-api 容器"
    echo "尝试查看所有容器..."
    docker ps -a --filter "ancestor=43.138.35.183:5000/wechat-api-net8:alpine-musl"
    exit 1
else
    echo "✅ 找到运行中的容器: $CONTAINER_ID"
fi

# 检查容器日志
echo ""
echo "[2] 检查容器启动日志..."
docker logs $CONTAINER_ID

# 检查端口映射
echo ""
echo "[3] 检查端口映射..."
docker port $CONTAINER_ID

# 检查容器网络配置
echo ""
echo "[4] 检查容器网络配置..."
docker inspect $CONTAINER_ID | grep -A 10 "NetworkSettings"

# 测试容器内部连接
echo ""
echo "[5] 测试容器内部API..."
docker exec $CONTAINER_ID sh -c "apk add --no-cache curl > /dev/null 2>&1; curl -s http://localhost:8080/swagger/index.html | head -5"

# 检查进程状态
echo ""
echo "[6] 检查容器内进程..."
docker exec $CONTAINER_ID ps aux

# 停止并重新创建容器（修复端口映射）
echo ""
echo "[7] 修复端口映射问题..."
echo "停止当前容器..."
docker stop $CONTAINER_ID
docker rm $CONTAINER_ID

echo "重新创建容器（正确的端口映射）..."
docker run -d \
  --name wechat-api-fixed \
  -p 8080:8080 \
  -p 8081:8081 \
  43.138.35.183:5000/wechat-api-net8:alpine-musl

# 等待容器启动
echo "等待容器启动..."
sleep 5

# 验证修复结果
NEW_CONTAINER_ID=$(docker ps -q --filter "name=wechat-api-fixed")
if [ -n "$NEW_CONTAINER_ID" ]; then
    echo "✅ 新容器启动成功: $NEW_CONTAINER_ID"
    echo ""
    echo "[8] 验证API访问..."
    echo "容器日志："
    docker logs $NEW_CONTAINER_ID
    echo ""
    echo "测试Swagger页面："
    curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/swagger/index.html
    echo ""
    echo ""
    echo "测试健康检查端点："
    curl -s http://localhost:8080/health || echo "健康检查端点可能不存在"
    echo ""
    echo ""
    echo "===== 修复完成！====="
    echo "API文档地址: http://localhost:8080/swagger"
    echo "API基础地址: http://localhost:8080"
    echo "HTTPS地址: https://localhost:8081 (如果有证书)"
else
    echo "❌ 新容器启动失败"
    exit 1
fi