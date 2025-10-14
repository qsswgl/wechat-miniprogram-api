@echo off
echo ===== 构建包含SSL证书的.NET 8 Alpine镜像 =====
echo.

:: 检查Docker是否安装
where docker >nul 2>&1
if %errorlevel% neq 0 (
    echo [×] 错误: 请先安装Docker Desktop
    pause
    exit /b 1
)
echo [√] Docker已安装

:: 检查证书文件
if not exist "certificates\qsgl.net.pfx" (
    echo [×] 错误: 找不到SSL证书文件 certificates\qsgl.net.pfx
    pause
    exit /b 1
)
echo [√] SSL证书文件存在

:: 配置信息
set PRIVATE_REGISTRY=43.138.35.183:5000
set IMAGE_NAME=wechat-api-net8
set TAG=alpine-with-ssl
set FULL_IMAGE=%PRIVATE_REGISTRY%/%IMAGE_NAME%:%TAG%

echo.
echo 镜像信息:
echo - 私有仓库: %PRIVATE_REGISTRY%
echo - 镜像名称: %IMAGE_NAME%:%TAG%
echo - 完整镜像名: %FULL_IMAGE%
echo - 基础镜像: Alpine Linux with musl libc + SSL证书
echo - 证书文件: certificates\qsgl.net.pfx
echo.

echo [1/5] 检查项目配置...
if not exist "WeChatMiniProgramAPI.csproj" (
    echo [×] 错误: 找不到项目文件 WeChatMiniProgramAPI.csproj
    pause
    exit /b 1
)
echo [√] 项目配置检查完成

echo [2/5] 清理环境...
:: 删除旧镜像
docker rmi -f %FULL_IMAGE% 2>nul
echo [√] 环境清理完成

echo [3/5] 构建包含SSL证书的Alpine镜像...
docker build -f Dockerfile.alpine-musl -t %FULL_IMAGE% .
if %errorlevel% neq 0 (
    echo [×] 错误: Docker构建失败
    pause
    exit /b 1
)
echo [√] Docker镜像构建成功

echo [4/5] 测试镜像（本地）...
:: 先测试镜像是否包含证书
docker run --rm %FULL_IMAGE% ls -la /app/certificates/
if %errorlevel% neq 0 (
    echo [×] 错误: 镜像中证书文件验证失败
    pause
    exit /b 1
)
echo [√] 证书文件已正确打包到镜像中

echo [5/5] 推送镜像到私有仓库...
echo 正在推送 %FULL_IMAGE% ...
docker push %FULL_IMAGE%
if %errorlevel% neq 0 (
    echo [×] 错误: 推送到私有仓库失败
    echo.
    echo 请确保:
    echo 1. 私有仓库 %PRIVATE_REGISTRY% 可访问
    echo 2. 已正确配置Docker Registry认证
    echo 3. 登录仓库: docker login %PRIVATE_REGISTRY%
    echo.
    echo 镜像已在本地构建: %FULL_IMAGE%
    pause
    exit /b 1
)

echo.
echo ===== 构建和推送成功! =====
echo.
echo 镜像详情:
echo - 本地镜像: %FULL_IMAGE%
echo - 私有仓库: %FULL_IMAGE%
echo - 内置SSL证书: ✅ qsgl.net.pfx
echo - 镜像大小: 
docker images --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}" | findstr %IMAGE_NAME%:%TAG%
echo.
echo 部署命令（Linux服务器）:
echo # 停止旧容器
echo docker stop wechat-api 2^>^/dev^/null ^|^| true
echo docker rm wechat-api 2^>^/dev^/null ^|^| true
echo.
echo # 拉取并运行新镜像
echo docker pull %FULL_IMAGE%
echo docker run -d \
echo   --name wechat-api \
echo   --restart unless-stopped \
echo   -p 8080:8080 \
echo   -p 8081:8081 \
echo   -p 8082:8082 \
echo   -e ASPNETCORE_ENVIRONMENT=Production \
echo   %FULL_IMAGE%
echo.
echo 访问地址:
echo HTTP: http://your-server-ip:8080
echo HTTPS: https://your-server-ip:8081
echo Swagger: http://your-server-ip:8080/swagger
echo.
pause