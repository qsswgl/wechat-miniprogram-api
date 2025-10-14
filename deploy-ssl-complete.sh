#!/bin/bash
echo "===== WeChat API SSL版本部署验证 ====="
echo ""

# 镜像信息
IMAGE="43.138.35.183:5000/wechat-api-net8:alpine-musl-ssl"

echo "🔍 [1] 检查当前容器状态..."
docker ps -a | grep wechat-api || echo "未找到wechat-api容器"

echo ""
echo "🛑 [2] 停止并清理旧容器..."
docker stop wechat-api 2>/dev/null && echo "✅ 已停止wechat-api" || echo "ℹ️ 容器未运行"
docker rm wechat-api 2>/dev/null && echo "✅ 已删除wechat-api" || echo "ℹ️ 容器不存在"

echo ""
echo "📥 [3] 拉取最新SSL版本镜像..."
docker pull $IMAGE

echo ""
echo "🚀 [4] 创建新的SSL版本容器..."
CONTAINER_ID=$(docker run -d \
  --name wechat-api \
  --restart unless-stopped \
  -p 8080:8080 \
  -p 8081:8081 \
  -p 8082:8082 \
  -e ASPNETCORE_ENVIRONMENT=Production \
  $IMAGE)

echo "容器ID: $CONTAINER_ID"

echo ""
echo "⏳ [5] 等待容器启动 (20秒)..."
for i in {1..20}; do
    sleep 1
    STATUS=$(docker inspect --format='{{.State.Status}}' wechat-api 2>/dev/null || echo "unknown")
    if [ "$STATUS" = "running" ]; then
        echo "✅ 容器已启动 ($i秒)"
        break
    elif [ "$STATUS" = "exited" ]; then
        echo "❌ 容器启动失败"
        break
    fi
    echo -n "."
done
echo ""

echo ""
echo "📊 [6] 容器状态检查..."
docker ps | head -1
docker ps | grep wechat-api || echo "❌ 容器未运行"

echo ""
echo "📋 [7] 容器启动日志..."
echo "--- 最近10条日志 ---"
docker logs wechat-api | tail -10

echo ""
echo "🔗 [8] 网络连接测试..."

# 检查端口监听
echo "检查端口监听状态:"
docker exec wechat-api netstat -tlnp 2>/dev/null | grep -E ':808[0-2]' || echo "端口检查失败"

echo ""
echo "API访问测试:"

# HTTP测试
echo -n "HTTP (8080): "
HTTP_CODE=$(timeout 10 curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/ 2>/dev/null)
if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "307" ] || [ "$HTTP_CODE" = "302" ]; then
    echo "✅ $HTTP_CODE"
else
    echo "❌ $HTTP_CODE"
fi

# Swagger测试
echo -n "Swagger (8080): "
SWAGGER_CODE=$(timeout 10 curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/swagger/index.html 2>/dev/null)
if [ "$SWAGGER_CODE" = "200" ]; then
    echo "✅ $SWAGGER_CODE"
else
    echo "❌ $SWAGGER_CODE"
fi

# HTTPS测试
echo -n "HTTPS (8081): "
HTTPS_CODE=$(timeout 10 curl -k -s -o /dev/null -w "%{http_code}" https://localhost:8081/ 2>/dev/null)
if [ "$HTTPS_CODE" = "200" ] || [ "$HTTPS_CODE" = "307" ] || [ "$HTTPS_CODE" = "302" ]; then
    echo "✅ $HTTPS_CODE"
else
    echo "❌ $HTTPS_CODE"
fi

# HTTPS Swagger测试
echo -n "HTTPS Swagger (8081): "
HTTPS_SWAGGER_CODE=$(timeout 10 curl -k -s -o /dev/null -w "%{http_code}" https://localhost:8081/swagger/index.html 2>/dev/null)
if [ "$HTTPS_SWAGGER_CODE" = "200" ]; then
    echo "✅ $HTTPS_SWAGGER_CODE"
else
    echo "❌ $HTTPS_SWAGGER_CODE"
fi

echo ""
echo "🔒 [9] SSL证书验证..."
docker exec wechat-api ls -la /app/certificates/ 2>/dev/null || echo "证书目录检查失败"

echo ""
echo "🌐 [10] 外部访问信息..."
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || echo "获取IP失败")
echo "服务器IP: $SERVER_IP"

echo ""
echo "====== 部署结果总结 ======"

# 检查最终状态
FINAL_STATUS=$(docker inspect --format='{{.State.Status}}' wechat-api 2>/dev/null)
if [ "$FINAL_STATUS" = "running" ]; then
    echo "✅ 部署成功！"
    echo ""
    echo "🌍 访问地址:"
    echo "  HTTP API: http://$SERVER_IP:8080"
    echo "  HTTPS API: https://$SERVER_IP:8081"  
    echo "  Swagger文档: http://$SERVER_IP:8080/swagger"
    echo "  HTTPS Swagger: https://$SERVER_IP:8081/swagger"
    echo ""
    echo "📋 管理命令:"
    echo "  实时日志: docker logs -f wechat-api"
    echo "  重启容器: docker restart wechat-api"
    echo "  停止容器: docker stop wechat-api"
    echo ""
    echo "🔐 SSL证书: 已内置到镜像中 (qsgl.net.pfx)"
else
    echo "❌ 部署失败！"
    echo "容器状态: $FINAL_STATUS"
    echo ""
    echo "🔧 故障排除:"
    echo "  查看详细日志: docker logs wechat-api"
    echo "  检查端口占用: netstat -tlnp | grep 808"
    echo "  重新部署: docker rm -f wechat-api && 重新运行部署命令"
fi

echo ""
echo "⭐ 部署脚本执行完成"