@echo off
echo ===== .NET 8 Alpine MUSL + SSL证书 独立部署到私有仓库 =====
echo.

:: 检查Docker是否安装
where docker >nul 2>&1
if %errorlevel% neq 0 (
    echo [×] 错误: 请先安装Docker Desktop
    pause
    exit /b 1
)
echo [√] Docker已安装
echo.

:: 配置信息
set PRIVATE_REGISTRY=43.138.35.183:5000
set IMAGE_NAME=wechat-api-net8
set TAG=alpine-musl-ssl
set FULL_IMAGE=%PRIVATE_REGISTRY%/%IMAGE_NAME%:%TAG%

echo 镜像信息:
echo - 私有仓库: %PRIVATE_REGISTRY%
echo - 镜像名称: %IMAGE_NAME%:%TAG%
echo - 完整镜像名: %FULL_IMAGE%
echo - 特性: Alpine Linux + musl libc + 内置SSL证书
echo.

echo [1/6] 检查项目配置...
if not exist "WeChatMiniProgramAPI.csproj" (
    echo [×] 错误: 找不到项目文件 WeChatMiniProgramAPI.csproj
    pause
    exit /b 1
)
echo [√] 项目配置检查完成

echo [2/6] 检查SSL证书文件...
if not exist "certificates\qsgl.net.pfx" (
    echo [×] 错误: 找不到SSL证书文件 certificates\qsgl.net.pfx
    echo 请确保证书文件存在于 certificates 目录中
    pause
    exit /b 1
)
echo [√] SSL证书文件检查完成

echo [3/6] 清理环境...
:: 删除旧容器
docker rm -f wechat-api-ssl-test 2>nul
:: 删除旧镜像
docker rmi -f %FULL_IMAGE% 2>nul
echo [√] 环境清理完成

echo [4/6] 构建Alpine MUSL + SSL镜像...
docker build -f Dockerfile.alpine-musl -t %FULL_IMAGE% .
if %errorlevel% neq 0 (
    echo [×] 错误: Docker构建失败
    pause
    exit /b 1
)
echo [√] Docker镜像构建成功

echo [5/6] 测试镜像...
docker run -d -p 8080:8080 -p 8081:8081 -p 8082:8082 --name wechat-api-ssl-test %FULL_IMAGE%
if %errorlevel% neq 0 (
    echo [×] 错误: 镜像启动失败
    pause
    exit /b 1
)
echo [√] 镜像测试启动成功

:: 等待容器启动
echo 等待容器启动...
timeout /t 10 /nobreak >nul

:: 检查容器状态
for /f "tokens=*" %%i in ('docker ps -q --filter "name=wechat-api-ssl-test"') do set CONTAINER_ID=%%i
if "%CONTAINER_ID%"=="" (
    echo [!] 警告: 容器启动后立即停止，查看日志...
    docker logs wechat-api-ssl-test 2>nul
    docker rm -f wechat-api-ssl-test 2>nul
) else (
    echo 容器状态: 运行中 (ID: %CONTAINER_ID%)
    echo 容器日志预览:
    docker logs wechat-api-ssl-test 2>nul | findstr /C:"listening" /C:"started" /C:"error" /C:"exception"
    echo.
    echo 测试HTTP访问:
    timeout /t 3 /nobreak >nul
    curl -s -o nul -w "HTTP状态: %%{http_code}" http://localhost:8080/ 2>nul || echo HTTP访问失败
    echo.
    echo 测试HTTPS访问:
    curl -k -s -o nul -w "HTTPS状态: %%{http_code}" https://localhost:8081/ 2>nul || echo HTTPS访问失败
    echo.
    docker rm -f wechat-api-ssl-test 2>nul
)

echo [6/6] 推送镜像到私有仓库...
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
echo ===== 部署成功! =====
echo.
echo 镜像详情:
echo - 本地镜像: %FULL_IMAGE%
echo - 私有仓库: %FULL_IMAGE%
echo - 内置SSL证书: qsgl.net.pfx (密码: qsgl2024)
echo - 镜像大小: 
docker images --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}" | findstr %IMAGE_NAME%:%TAG%
echo.
echo 部署命令示例:
echo docker run -d -p 8080:8080 -p 8081:8081 -p 8082:8082 --name wechat-api %FULL_IMAGE%
echo.
echo 镜像拉取命令:
echo docker pull %FULL_IMAGE%
echo.
echo 访问地址:
echo HTTP: http://your-server-ip:8080
echo HTTPS: https://your-server-ip:8081
echo Swagger: http://your-server-ip:8080/swagger
echo.
pause