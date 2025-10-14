@echo off
echo ===== WeChat API Linux服务器部署脚本 =====
echo.

:: 检查镜像是否存在并拉取最新版本
echo [1] 拉取最新镜像到Linux服务器...
echo docker pull 43.138.35.183:5000/wechat-api-net8:alpine-musl

echo.
echo [2] 清理旧容器...
echo docker stop wechat-api 2^>^/dev^/null ^|^| true
echo docker rm wechat-api 2^>^/dev^/null ^|^| true

echo.
echo [3] 创建证书目录并上传证书（如果需要）...
echo mkdir -p /root/certificates
echo # 将证书文件上传到服务器的 /root/certificates/ 目录

echo.
echo [4] 创建新容器（支持HTTPS）...
echo docker run -d \
echo   --name wechat-api \
echo   --restart unless-stopped \
echo   -p 8080:8080 \
echo   -p 8081:8081 \
echo   -p 8082:8082 \
echo   -v /root/certificates:/app/certificates:ro \
echo   -e ASPNETCORE_ENVIRONMENT=Production \
echo   43.138.35.183:5000/wechat-api-net8:alpine-musl

echo.
echo [5] 检查部署状态...
echo # 等待5秒
echo sleep 5

echo.
echo # 检查容器状态
echo docker ps ^| grep wechat-api

echo.
echo # 查看容器日志
echo docker logs wechat-api ^| tail -10

echo.
echo # 测试HTTP访问
echo curl http://localhost:8080/swagger/index.html

echo.
echo # 测试HTTPS访问（如果证书配置正确）
echo curl -k https://localhost:8081/swagger/index.html

echo.
echo ===== 部署完成 =====
echo HTTP访问: http://your-server-ip:8080
echo HTTPS访问: https://your-server-ip:8081
echo Swagger文档: http://your-server-ip:8080/swagger
echo.
echo 容器管理命令:
echo 查看日志: docker logs -f wechat-api
echo 重启容器: docker restart wechat-api
echo 停止容器: docker stop wechat-api
echo.
pause