#!/bin/bash
echo "===== WeChat API 完整部署脚本（支持HTTPS） ====="
echo ""

# 检查镜像是否存在
echo "[1] 检查Docker镜像..."
if ! docker images | grep -q "43.138.35.183:5000/wechat-api-net8:alpine-musl"; then
    echo "拉取最新镜像..."
    docker pull 43.138.35.183:5000/wechat-api-net8:alpine-musl
fi

# 停止并删除已存在的容器
echo "[2] 清理旧容器..."
docker stop wechat-api 2>/dev/null || true
docker rm wechat-api 2>/dev/null || true
docker stop wechat-api-new 2>/dev/null || true
docker rm wechat-api-new 2>/dev/null || true

# 创建证书目录（如果需要）
echo "[3] 准备证书目录..."
mkdir -p ./certificates

# 检查证书是否存在（假设证书在当前目录的certificates文件夹中）
if [ -f "./certificates/qsgl.net.pfx" ]; then
    echo "✅ 找到SSL证书: ./certificates/qsgl.net.pfx"
    CERT_MOUNT="-v $(pwd)/certificates:/app/certificates:ro"
else
    echo "⚠️  未找到SSL证书，将只支持HTTP访问"
    CERT_MOUNT=""
fi

# 创建新容器
echo "[4] 创建新容器..."
docker run -d \
  --name wechat-api \
  --restart unless-stopped \
  -p 8080:8080 \
  -p 8081:8081 \
  -p 8082:8082 \
  -p 8083:8083 \
  $CERT_MOUNT \
  -e ASPNETCORE_ENVIRONMENT=Production \
  -e ASPNETCORE_URLS="http://+:8080" \
  43.138.35.183:5000/wechat-api-net8:alpine-musl

# 等待容器启动
echo "等待容器启动..."
sleep 5

# 检查容器状态
CONTAINER_ID=$(docker ps -q --filter "name=wechat-api")
if [ -n "$CONTAINER_ID" ]; then
    echo "✅ 容器启动成功: $CONTAINER_ID"
    
    echo ""
    echo "[5] 容器信息..."
    docker ps | grep wechat-api
    
    echo ""
    echo "[6] 检查容器日志..."
    docker logs wechat-api | tail -10
    
    echo ""
    echo "[7] 检查端口监听..."
    docker exec wechat-api sh -c "netstat -tlnp 2>/dev/null | grep ':8080' || ss -tlnp | grep ':8080' || echo '端口检查命令不可用'"
    
    echo ""
    echo "[8] 测试API访问..."
    echo "HTTP测试:"
    curl -s -o /dev/null -w "状态码: %{http_code}\n" http://localhost:8080/ || echo "HTTP访问失败"
    
    echo "Swagger测试:"
    curl -s -o /dev/null -w "状态码: %{http_code}\n" http://localhost:8080/swagger/index.html || echo "Swagger访问失败"
    
    if [ -f "./certificates/qsgl.net.pfx" ]; then
        echo "HTTPS测试:"
        curl -k -s -o /dev/null -w "状态码: %{http_code}\n" https://localhost:8081/ || echo "HTTPS访问失败"
    fi
    
    echo ""
    echo "===== 部署完成 ====="
    echo "HTTP访问地址: http://localhost:8080"
    echo "Swagger文档: http://localhost:8080/swagger"
    if [ -f "./certificates/qsgl.net.pfx" ]; then
        echo "HTTPS访问地址: https://localhost:8081"
        echo "HTTPS Swagger: https://localhost:8081/swagger"
    fi
    echo ""
    echo "容器管理命令:"
    echo "查看日志: docker logs -f wechat-api"
    echo "停止容器: docker stop wechat-api"
    echo "启动容器: docker start wechat-api"
    
else
    echo "❌ 容器启动失败"
    echo "检查Docker日志:"
    docker logs wechat-api 2>/dev/null || echo "无法获取日志"
    exit 1
fi