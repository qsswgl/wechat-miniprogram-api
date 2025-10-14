@echo off
echo ===== 重新构建启用Swagger的生产版本 =====
echo.

:: 配置信息
set PRIVATE_REGISTRY=43.138.35.183:5000
set IMAGE_NAME=wechat-api-net8
set TAG=alpine-musl-ssl-swagger
set FULL_IMAGE=%PRIVATE_REGISTRY%/%IMAGE_NAME%:%TAG%

echo 镜像信息:
echo - 私有仓库: %PRIVATE_REGISTRY%
echo - 镜像名称: %IMAGE_NAME%:%TAG%
echo - 完整镜像名: %FULL_IMAGE%
echo - 特性: Alpine Linux + SSL证书 + 生产环境Swagger
echo.

echo [1/4] 快速构建修复版本...
docker build -f Dockerfile.alpine-musl -t %FULL_IMAGE% .
if %errorlevel% neq 0 (
    echo [×] 构建失败
    pause
    exit /b 1
)
echo [√] 构建成功

echo [2/4] 推送到私有仓库...
docker push %FULL_IMAGE%
if %errorlevel% neq 0 (
    echo [×] 推送失败
    pause
    exit /b 1
)
echo [√] 推送成功

echo [3/4] 测试镜像...
docker run --rm -d -p 8095:8080 -p 8096:8081 --name test-swagger-fix %FULL_IMAGE%
timeout /t 10 /nobreak >nul
docker logs test-swagger-fix | findstr /C:"listening" /C:"started" | tail -3
echo.
echo 测试Swagger访问:
curl -s -o nul -w "HTTP状态: %%{http_code}" http://localhost:8095/swagger/index.html 2>nul || echo HTTP测试失败
echo.
docker rm -f test-swagger-fix 2>nul

echo [4/4] 部署命令...
echo.
echo ===== 修复完成! =====
echo.
echo 在服务器上执行以下命令更新:
echo.
echo # 停止当前容器
echo docker stop wechat-api
echo docker rm wechat-api
echo.
echo # 部署修复版本
echo docker run -d \
echo   --name wechat-api \
echo   --restart unless-stopped \
echo   -p 8090:8080 \
echo   -p 8091:8081 \
echo   -p 8092:8082 \
echo   -e ASPNETCORE_ENVIRONMENT=Production \
echo   %FULL_IMAGE%
echo.
pause