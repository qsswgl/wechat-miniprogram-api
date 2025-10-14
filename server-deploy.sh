#!/bin/bash

# WeChat API Linux服务器部署脚本
# 使用方法: curl -s https://your-domain/deploy.sh | bash
# 或者: wget -O - https://your-domain/deploy.sh | bash

echo "===== WeChat API 服务器部署脚本 ====="
echo ""

# 检查Docker是否安装
if ! command -v docker &> /dev/null; then
    echo "❌ Docker未安装，请先安装Docker"
    exit 1
fi

echo "✅ Docker已安装"

# 拉取最新镜像
echo ""
echo "[1] 拉取最新镜像..."
docker pull 43.138.35.183:5000/wechat-api-net8:alpine-musl

# 停止并删除旧容器
echo ""
echo "[2] 清理旧容器..."
docker stop wechat-api 2>/dev/null || true
docker rm wechat-api 2>/dev/null || true

# 检查证书
echo ""
echo "[3] 检查SSL证书..."
if [ -f "/root/certificates/qsgl.net.pfx" ]; then
    echo "✅ 找到SSL证书: /root/certificates/qsgl.net.pfx"
    CERT_MOUNT="-v /root/certificates:/app/certificates:ro"
    HTTPS_ENABLED=true
else
    echo "⚠️ 未找到SSL证书，创建证书目录..."
    mkdir -p /root/certificates
    echo "请将 qsgl.net.pfx 证书文件上传到 /root/certificates/ 目录"
    CERT_MOUNT=""
    HTTPS_ENABLED=false
fi

# 创建容器
echo ""
echo "[4] 创建WeChat API容器..."
if [ "$HTTPS_ENABLED" = true ]; then
    echo "启用HTTPS支持..."
    docker run -d \
      --name wechat-api \
      --restart unless-stopped \
      -p 8080:8080 \
      -p 8081:8081 \
      -p 8082:8082 \
      $CERT_MOUNT \
      -e ASPNETCORE_ENVIRONMENT=Production \
      43.138.35.183:5000/wechat-api-net8:alpine-musl
else
    echo "仅启用HTTP支持..."
    docker run -d \
      --name wechat-api \
      --restart unless-stopped \
      -p 8080:8080 \
      -e ASPNETCORE_ENVIRONMENT=Production \
      -e ASPNETCORE_URLS="http://+:8080" \
      43.138.35.183:5000/wechat-api-net8:alpine-musl
fi

# 等待启动
echo "等待容器启动..."
sleep 8

# 检查容器状态
CONTAINER_ID=$(docker ps -q --filter "name=wechat-api")
if [ -n "$CONTAINER_ID" ]; then
    echo ""
    echo "✅ 容器启动成功!"
    echo "容器ID: $CONTAINER_ID"
    
    echo ""
    echo "[5] 容器状态信息:"
    docker ps | head -1  # 表头
    docker ps | grep wechat-api
    
    echo ""
    echo "[6] 应用启动日志:"
    docker logs wechat-api | tail -15
    
    echo ""
    echo "[7] 网络连接测试:"
    
    # 测试HTTP
    echo "测试HTTP访问..."
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/ 2>/dev/null || echo "000")
    if [ "$HTTP_STATUS" -eq "200" ] || [ "$HTTP_STATUS" -eq "404" ] || [ "$HTTP_STATUS" -eq "302" ]; then
        echo "✅ HTTP (8080): 可访问 (状态码: $HTTP_STATUS)"
    else
        echo "❌ HTTP (8080): 不可访问 (状态码: $HTTP_STATUS)"
    fi
    
    # 测试Swagger
    SWAGGER_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/swagger/index.html 2>/dev/null || echo "000")
    if [ "$SWAGGER_STATUS" -eq "200" ]; then
        echo "✅ Swagger文档: 可访问"
    else
        echo "❌ Swagger文档: 不可访问 (状态码: $SWAGGER_STATUS)"
    fi
    
    # 测试HTTPS（如果启用）
    if [ "$HTTPS_ENABLED" = true ]; then
        HTTPS_STATUS=$(curl -k -s -o /dev/null -w "%{http_code}" https://localhost:8081/ 2>/dev/null || echo "000")
        if [ "$HTTPS_STATUS" -eq "200" ] || [ "$HTTPS_STATUS" -eq "404" ] || [ "$HTTPS_STATUS" -eq "302" ]; then
            echo "✅ HTTPS (8081): 可访问 (状态码: $HTTPS_STATUS)"
        else
            echo "❌ HTTPS (8081): 不可访问 (状态码: $HTTPS_STATUS)"
        fi
    fi
    
    echo ""
    echo "===== 部署完成! ====="
    echo ""
    
    # 获取服务器IP
    SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || echo "your-server-ip")
    
    echo "🌐 访问地址:"
    echo "   HTTP API: http://$SERVER_IP:8080"
    echo "   Swagger: http://$SERVER_IP:8080/swagger"
    
    if [ "$HTTPS_ENABLED" = true ]; then
        echo "   HTTPS API: https://$SERVER_IP:8081"
        echo "   HTTPS Swagger: https://$SERVER_IP:8081/swagger"
    fi
    
    echo ""
    echo "📋 管理命令:"
    echo "   查看日志: docker logs -f wechat-api"
    echo "   重启容器: docker restart wechat-api"
    echo "   停止容器: docker stop wechat-api"
    echo "   删除容器: docker rm -f wechat-api"
    
    if [ "$HTTPS_ENABLED" = false ]; then
        echo ""
        echo "💡 启用HTTPS支持:"
        echo "   1. 上传证书到: /root/certificates/qsgl.net.pfx"
        echo "   2. 重新运行此脚本"
    fi
    
else
    echo ""
    echo "❌ 容器启动失败!"
    echo "检查错误日志:"
    docker logs wechat-api 2>/dev/null || echo "无法获取日志"
    
    echo ""
    echo "可能的问题:"
    echo "1. 端口被占用 (检查: netstat -tlnp | grep 8080)"
    echo "2. 镜像损坏 (重新拉取: docker pull 43.138.35.183:5000/wechat-api-net8:alpine-musl)"
    echo "3. 配置问题 (检查证书路径和权限)"
    
    exit 1
fi