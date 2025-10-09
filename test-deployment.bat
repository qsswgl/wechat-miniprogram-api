@echo off
chcp 65001 >nul
echo ===============================================
echo     QSGL API - 部署后验证测试
echo ===============================================
echo.

set SERVER_IP=123.57.93.200

echo 🔍 正在测试服务可用性...
echo.

echo [测试 1] HTTP端口 8080...
curl -I http://%SERVER_IP%:8080/swagger/index.html --connect-timeout 10
if errorlevel 1 (
    echo ❌ HTTP:8080 访问失败
) else (
    echo ✅ HTTP:8080 访问正常
)

echo.
echo [测试 2] HTTPS端口 8081...
curl -I https://%SERVER_IP%:8081/swagger/index.html -k --connect-timeout 10
if errorlevel 1 (
    echo ❌ HTTPS:8081 访问失败
) else (
    echo ✅ HTTPS:8081 访问正常
)

echo.
echo [测试 3] 容器运行状态...
ssh root@%SERVER_IP% "cd /opt/qsgl-api && docker-compose ps"

echo.
echo [测试 4] 服务日志（最后10行）...
ssh root@%SERVER_IP% "cd /opt/qsgl-api && docker-compose logs --tail=10"

echo.
echo ===============================================
echo 🌐 访问地址：
echo   Swagger文档: http://%SERVER_IP%:8080/swagger
echo   API测试: http://%SERVER_IP%:8080/api/WeChat/CreateMiniProgramCode
echo.
echo 📋 管理命令：
echo   查看完整日志: ssh root@%SERVER_IP% "cd /opt/qsgl-api && docker-compose logs -f"
echo   重启服务: ssh root@%SERVER_IP% "cd /opt/qsgl-api && docker-compose restart"
echo   停止服务: ssh root@%SERVER_IP% "cd /opt/qsgl-api && docker-compose down"
echo ===============================================

pause