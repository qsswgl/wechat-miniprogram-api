#!/bin/bash
echo "===== 部署包含SSL证书的WeChat API镜像 ====="
echo ""

# 镜像信息
REGISTRY="43.138.35.183:5000"
IMAGE_NAME="wechat-api-net8"
TAG="alpine-musl-ssl"
FULL_IMAGE="$REGISTRY/$IMAGE_NAME:$TAG"

echo "镜像信息："
echo "- 镜像名称: $FULL_IMAGE"
echo "- 特性: 内置SSL证书，支持HTTP/HTTPS"
echo ""

echo "[1] 停止并删除旧容器..."
docker stop wechat-api 2>/dev/null || true
docker rm wechat-api 2>/dev/null || true

echo "[2] 拉取最新镜像..."
docker pull $FULL_IMAGE

echo "[3] 创建新容器..."
docker run -d \
  --name wechat-api \
  --restart unless-stopped \
  -p 8080:8080 \
  -p 8081:8081 \
  -p 8082:8082 \
  -e ASPNETCORE_ENVIRONMENT=Production \
  $FULL_IMAGE

echo ""
echo "[4] 等待容器启动..."
sleep 15

echo "[5] 检查容器状态..."
CONTAINER_ID=$(docker ps -q --filter "name=wechat-api")
if [ -n "$CONTAINER_ID" ]; then
    echo "✅ 容器启动成功: $CONTAINER_ID"
    
    echo ""
    echo "容器详情:"
    docker ps | head -1  # 表头
    docker ps | grep wechat-api
    
    echo ""
    echo "应用启动日志:"
    docker logs wechat-api | tail -10
    
    echo ""
    echo "[6] 测试API访问..."
    
    # 测试HTTP
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/ 2>/dev/null || echo "000")
    echo "HTTP (8080): $HTTP_STATUS"
    
    # 测试Swagger
    SWAGGER_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/swagger/index.html 2>/dev/null || echo "000")
    echo "Swagger: $SWAGGER_STATUS"
    
    # 测试HTTPS
    HTTPS_STATUS=$(curl -k -s -o /dev/null -w "%{http_code}" https://localhost:8081/ 2>/dev/null || echo "000")
    echo "HTTPS (8081): $HTTPS_STATUS"
    
    # 测试HTTPS Swagger
    HTTPS_SWAGGER_STATUS=$(curl -k -s -o /dev/null -w "%{http_code}" https://localhost:8081/swagger/index.html 2>/dev/null || echo "000")
    echo "HTTPS Swagger: $HTTPS_SWAGGER_STATUS"
    
    echo ""
    echo "===== 部署完成！ ====="
    
    # 获取服务器IP
    SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || echo "your-server-ip")
    
    echo ""
    echo "🌐 访问地址："
    echo "  HTTP API: http://$SERVER_IP:8080"
    echo "  HTTPS API: https://$SERVER_IP:8081"
    echo "  HTTP Swagger: http://$SERVER_IP:8080/swagger"
    echo "  HTTPS Swagger: https://$SERVER_IP:8081/swagger"
    
    echo ""
    echo "📋 管理命令："
    echo "  查看日志: docker logs -f wechat-api"
    echo "  重启容器: docker restart wechat-api"
    echo "  停止容器: docker stop wechat-api"
    
    echo ""
    echo "🔒 SSL证书信息："
    echo "  证书文件: 内置 qsgl.net.pfx"
    echo "  证书密码: qsgl2024"
    echo "  支持域名: *.qsgl.net, qsgl.net"
    
else
    echo "❌ 容器启动失败！"
    echo ""
    echo "错误日志："
    docker logs wechat-api 2>/dev/null || echo "无法获取日志"
    
    echo ""
    echo "可能的问题："
    echo "1. 端口被占用"
    echo "2. 镜像损坏"
    echo "3. 配置问题"
    
    exit 1
fi