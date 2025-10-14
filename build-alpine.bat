@echo off
chcp 65001 >nul
echo ===== .NET 8 Alpine独立部署到私有仓库 =====
echo.

REM 检查Docker
docker --version >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [错误] Docker未安装
    pause
    exit /b 1
)

echo [√] Docker已安装

REM 设置变量
set PRIVATE_REGISTRY=43.138.35.183:5000
set IMAGE_NAME=wechat-api-net8
set IMAGE_TAG=alpine
set FULL_IMAGE_NAME=%PRIVATE_REGISTRY%/%IMAGE_NAME%:%IMAGE_TAG%

echo.
echo 镜像信息:
echo - 私有仓库: %PRIVATE_REGISTRY%
echo - 镜像名称: %IMAGE_NAME%:%IMAGE_TAG%
echo - 完整镜像名: %FULL_IMAGE_NAME%
echo - 基础镜像: Alpine Linux (更小更安全)
echo.

echo [1/5] 检查项目配置...
if not exist "WeChatMiniProgramAPI.csproj" (
    echo [错误] 项目文件不存在
    pause
    exit /b 1
)
echo [√] 项目配置检查完成

echo [2/5] 清理环境...
docker image prune -f >nul 2>&1
echo [√] 环境清理完成

echo [3/5] 构建Alpine独立部署镜像...
docker build -f Dockerfile.alpine -t %FULL_IMAGE_NAME% .
if %ERRORLEVEL% NEQ 0 (
    echo [错误] Docker镜像构建失败
    pause
    exit /b 1
)
echo [√] Docker镜像构建成功

echo [4/5] 测试镜像...
docker run --rm -d --name test-wechat-alpine -p 18080:8080 %FULL_IMAGE_NAME%
if %ERRORLEVEL% EQU 0 (
    echo [√] 镜像测试启动成功
    timeout /t 10 /nobreak >nul
    echo 容器日志预览:
    docker logs test-wechat-alpine --tail=10
    docker stop test-wechat-alpine >nul 2>&1
) else (
    echo [警告] 测试启动失败，但镜像已构建成功
)

echo [5/5] 推送镜像到私有仓库...
echo 正在推送 %FULL_IMAGE_NAME% ...
docker push %FULL_IMAGE_NAME%
if %ERRORLEVEL% NEQ 0 (
    echo [错误] 镜像推送失败
    echo.
    echo 可能需要:
    echo 1. 检查网络连接: ping 43.138.35.183
    echo 2. 配置不安全仓库 (如果使用HTTP)
    echo 3. 登录仓库: docker login %PRIVATE_REGISTRY%
    echo.
    echo 镜像已在本地构建: %FULL_IMAGE_NAME%
    pause
    exit /b 1
)

echo [√] 镜像推送成功！

REM 显示镜像信息
echo.
echo ===== 部署完成! =====
echo.
echo 🎉 .NET 8 Alpine独立部署镜像已成功推送！
echo.
echo 📋 镜像详情:
echo - 仓库镜像: %FULL_IMAGE_NAME%
echo - 部署类型: .NET 8 独立部署 (Self-contained)
echo - 基础镜像: Alpine Linux (~50MB)
echo - 安全特性: 非root用户运行
echo.
echo 🚀 在目标服务器上部署:
echo docker pull %FULL_IMAGE_NAME%
echo docker run -d --name wechat-api -p 8080:8080 %FULL_IMAGE_NAME%
echo.
echo 🔍 验证部署:
echo curl http://服务器IP:8080/swagger
echo docker logs wechat-api
echo.

REM 显示镜像大小
docker images %FULL_IMAGE_NAME%

echo.
echo 部署成功完成！
pause