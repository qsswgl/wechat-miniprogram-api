#!/bin/bash
echo "🔍 WeChat API 端口冲突解决方案"
echo "================================"

echo ""
echo "📊 [1] 检查端口占用情况..."
echo "检查8080端口占用:"
netstat -tlnp | grep :8080 || echo "netstat未找到8080端口占用"
ss -tlnp | grep :8080 || echo "ss未找到8080端口占用"

echo ""
echo "🐳 [2] 检查Docker容器占用8080端口..."
docker ps --format "table {{.Names}}\t{{.Ports}}" | grep 8080

echo ""
echo "📋 [3] 检查所有运行的容器..."
docker ps

echo ""
echo "🛑 [4] 解决方案选择..."
echo "选择解决方案:"
echo "A) 停止占用8080端口的容器"
echo "B) 使用不同端口部署wechat-api" 
echo ""

# 找出占用8080的容器
CONFLICTING_CONTAINER=$(docker ps --filter "publish=8080" --format "{{.Names}}" | head -1)
if [ -n "$CONFLICTING_CONTAINER" ]; then
    echo "🚨 发现占用8080端口的容器: $CONFLICTING_CONTAINER"
    echo ""
    echo "方案A - 停止冲突容器 (推荐):"
    echo "docker stop $CONFLICTING_CONTAINER"
    echo "docker rm $CONFLICTING_CONTAINER"
    echo ""
    echo "然后重新运行wechat-api"
    echo ""
    echo "方案B - 使用备用端口:"
    echo "docker run -d \\"
    echo "  --name wechat-api \\"
    echo "  --restart unless-stopped \\"
    echo "  -p 8090:8080 \\"
    echo "  -p 8091:8081 \\"
    echo "  -p 8092:8082 \\"
    echo "  -e ASPNETCORE_ENVIRONMENT=Production \\"
    echo "  43.138.35.183:5000/wechat-api-net8:alpine-musl-ssl"
    echo ""
    echo "访问地址将变为: http://server-ip:8090"
else
    echo "❓ 未通过Docker检测到8080端口占用"
    echo "可能是系统服务占用，请检查:"
    echo "sudo lsof -i:8080"
fi