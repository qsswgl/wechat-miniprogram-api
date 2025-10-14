#!/bin/bash
echo "===== 修复 WeChat API 容器端口映射问题 ====="
echo ""

# 当前容器信息
echo "[1] 当前容器状态:"
docker ps | grep wechat-api

echo ""
echo "[2] 当前端口映射问题:"
echo "显示的映射: 0.0.0.0:8080-8081->8080-8081/tcp"
echo "这是端口范围映射，不是我们需要的单独端口映射"

echo ""
echo "[3] 停止并删除当前容器..."
docker stop wechat-api
docker rm wechat-api

echo ""
echo "[4] 重新创建容器（正确的端口映射）..."
docker run -d \
  --name wechat-api \
  --restart unless-stopped \
  -p 8080:8080 \
  -p 8081:8081 \
  -p 8082:8082 \
  -v /root/certificates:/app/certificates:ro \
  -e ASPNETCORE_ENVIRONMENT=Production \
  43.138.35.183:5000/wechat-api-net8:alpine-musl

echo ""
echo "[5] 等待容器启动..."
sleep 8

echo ""
echo "[6] 验证新的端口映射:"
docker ps | grep wechat-api

echo ""
echo "[7] 检查应用启动状态:"
docker logs wechat-api | tail -10

echo ""
echo "[8] 测试端口连接:"

# 测试HTTP端口
echo "测试HTTP (8080)..."
timeout 5 bash -c '</dev/tcp/localhost/8080' && echo "✅ 8080端口可连接" || echo "❌ 8080端口连接失败"

# 测试HTTPS端口  
echo "测试HTTPS (8081)..."
timeout 5 bash -c '</dev/tcp/localhost/8081' && echo "✅ 8081端口可连接" || echo "❌ 8081端口连接失败"

echo ""
echo "[9] 测试API访问:"

# 测试根路径
echo "测试根路径..."
curl -s -o /dev/null -w "根路径状态码: %{http_code}\n" http://localhost:8080/ || echo "根路径访问失败"

# 测试健康检查端点
echo "测试健康检查..."
curl -s -o /dev/null -w "健康检查状态码: %{http_code}\n" http://localhost:8080/health || echo "健康检查端点可能不存在"

# 测试Swagger
echo "测试Swagger文档..."
curl -s -o /dev/null -w "Swagger状态码: %{http_code}\n" http://localhost:8080/swagger/index.html || echo "Swagger访问失败"

# 测试HTTPS
echo "测试HTTPS访问..."
curl -k -s -o /dev/null -w "HTTPS状态码: %{http_code}\n" https://localhost:8081/ || echo "HTTPS访问失败"

echo ""
echo "[10] 容器内部诊断:"
echo "检查容器内部网络监听..."
docker exec wechat-api netstat -tlnp | grep -E ':(8080|8081)'

echo ""
echo "检查容器内部进程..."
docker exec wechat-api ps aux | head -5

echo ""
echo "测试容器内部HTTP访问..."
docker exec wechat-api sh -c "wget -qO- --timeout=5 http://localhost:8080/ 2>/dev/null | head -1 || echo '容器内部HTTP访问失败'"

echo ""
echo "===== 修复完成 ====="
echo ""
echo "如果API仍然不可访问，可能的原因:"
echo "1. 应用程序启动时间较长，需要等待更长时间"
echo "2. 应用程序配置问题，检查日志获取更多信息"
echo "3. 防火墙或安全组限制"
echo ""
echo "访问地址:"
echo "HTTP: http://$(curl -s ifconfig.me 2>/dev/null || echo 'your-server-ip'):8080"
echo "HTTPS: https://$(curl -s ifconfig.me 2>/dev/null || echo 'your-server-ip'):8081"
echo "Swagger: http://$(curl -s ifconfig.me 2>/dev/null || echo 'your-server-ip'):8080/swagger"