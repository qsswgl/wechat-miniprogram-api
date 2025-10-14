#!/bin/bash
echo "🔍 WeChat API Swagger诊断工具"
echo "============================="

echo ""
echo "📊 [1] 基本信息确认..."
echo "容器状态:"
docker ps | grep wechat-api

echo ""
echo "📋 [2] 详细日志分析..."
echo "启动日志 (最近20条):"
docker logs wechat-api | tail -20

echo ""
echo "🔗 [3] 测试不同的API路径..."

# 测试根路径
echo "测试根路径:"
curl -k -s -I https://localhost:8091/ | head -3

# 测试常见的Swagger路径
echo ""
echo "测试Swagger路径:"
PATHS=(
    "/swagger"
    "/swagger/index.html"
    "/swagger/v1/swagger.json"
    "/api-docs"
    "/docs"
    "/api"
    "/weatherforecast"
    "/health"
    "/"
)

for path in "${PATHS[@]}"; do
    echo -n "$path: "
    STATUS=$(curl -k -s -o /dev/null -w "%{http_code}" https://localhost:8091$path 2>/dev/null)
    echo "$STATUS"
done

echo ""
echo "🔧 [4] 容器内部检查..."
echo "检查应用文件结构:"
docker exec wechat-api ls -la / 2>/dev/null || echo "无法访问容器内部"

echo ""
echo "检查wwwroot目录:"
docker exec wechat-api ls -la /app/wwwroot/ 2>/dev/null || echo "wwwroot目录不存在或无法访问"

echo ""
echo "检查配置文件:"
docker exec wechat-api cat /app/appsettings.json 2>/dev/null | head -10 || echo "无法读取配置文件"

echo ""
echo "🌐 [5] 测试HTTP访问..."
echo "HTTP根路径:"
curl -s -I http://localhost:8090/ | head -3

echo ""
echo "HTTP Swagger:"
curl -s -o /dev/null -w "HTTP Swagger状态: %{http_code}\n" http://localhost:8090/swagger/index.html

echo ""
echo "📝 [6] 环境变量检查..."
docker exec wechat-api printenv | grep -E "(ASPNET|DOTNET)" 2>/dev/null || echo "无法获取环境变量"

echo ""
echo "🔍 [7] 进程检查..."
docker exec wechat-api ps aux 2>/dev/null || echo "无法检查进程"

echo ""
echo "================= 诊断完成 ================="