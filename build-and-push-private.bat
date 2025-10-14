@echo off
chcp 65001 >nul
REM ===== .NET 8 独立部署到私有Docker仓库 =====
echo.
echo ===== .NET 8 独立部署到私有Docker仓库 =====
echo.

REM 检查Docker是否已安装
docker --version >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [错误] 未检测到Docker，请先安装Docker Desktop
    echo 下载地址: https://www.docker.com/products/docker-desktop
    pause
    exit /b 1
)

echo [√] Docker已安装

REM 设置变量
set PRIVATE_REGISTRY=43.138.35.183:5000
set IMAGE_NAME=wechat-api-net8
set IMAGE_TAG=latest
set FULL_IMAGE_NAME=%PRIVATE_REGISTRY%/%IMAGE_NAME%:%IMAGE_TAG%

echo.
echo 镜像信息:
echo - 私有仓库: %PRIVATE_REGISTRY%
echo - 镜像名称: %IMAGE_NAME%
echo - 标签: %IMAGE_TAG%
echo - 完整镜像名: %FULL_IMAGE_NAME%
echo.

REM 检查项目配置
echo [1/6] 检查项目配置...
if not exist "WeChatMiniProgramAPI.csproj" (
    echo [错误] 找不到项目文件，请在项目根目录运行此脚本
    pause
    exit /b 1
)

REM 查找.NET 8项目配置
findstr "net8.0" WeChatMiniProgramAPI.csproj >nul
if %ERRORLEVEL% NEQ 0 (
    echo [警告] 项目可能不是.NET 8，请检查项目配置
)

echo [√] 项目配置检查完成

REM 清理旧的构建
echo [2/6] 清理环境...
docker image prune -f >nul 2>&1
echo [√] 环境清理完成

REM 构建Docker镜像
echo [3/6] 构建.NET 8独立部署镜像...
docker build -f Dockerfile.net8 -t %FULL_IMAGE_NAME% .
if %ERRORLEVEL% NEQ 0 (
    echo [错误] Docker镜像构建失败
    pause
    exit /b 1
)
echo [√] Docker镜像构建成功

REM 测试镜像
echo [4/6] 测试镜像...
docker run --rm -d --name test-wechat-api-net8 -p 18080:8080 %FULL_IMAGE_NAME%
if %ERRORLEVEL% NEQ 0 (
    echo [警告] 镜像测试启动失败，继续推送流程
) else (
    echo [√] 镜像测试启动成功
    timeout /t 10 /nobreak >nul
    docker logs test-wechat-api-net8
    docker stop test-wechat-api-net8 >nul 2>&1
fi

REM 配置私有仓库（允许不安全连接）
echo [5/6] 配置私有仓库连接...
echo 注意: 如果私有仓库使用HTTP，需要配置Docker允许不安全连接
echo 请确保Docker配置中包含: "insecure-registries": ["%PRIVATE_REGISTRY%"]
echo.

REM 推送镜像到私有仓库
echo [6/6] 推送镜像到私有仓库...
docker push %FULL_IMAGE_NAME%
if %ERRORLEVEL% NEQ 0 (
    echo [错误] 镜像推送失败
    echo.
    echo 可能的原因:
    echo 1. 私有仓库 %PRIVATE_REGISTRY% 无法访问
    echo 2. 需要登录认证: docker login %PRIVATE_REGISTRY%
    echo 3. 需要配置不安全仓库（如果是HTTP）
    echo.
    echo 解决方案:
    echo 1. 检查网络连接: ping 43.138.35.183
    echo 2. 配置Docker允许不安全仓库
    echo 3. 如需认证: docker login %PRIVATE_REGISTRY%
    echo.
    pause
    exit /b 1
)

echo [√] 镜像推送成功！

REM 显示成功信息
echo.
echo ===== 部署成功! =====
echo.
echo 🎉 .NET 8独立部署镜像已成功推送！
echo.
echo 📋 镜像信息:
echo - 私有仓库镜像: %FULL_IMAGE_NAME%
echo - 部署类型: .NET 8 独立部署（Self-contained）
echo - 基础镜像: Ubuntu 22.04
echo.
echo 🚀 在目标服务器上运行:
echo docker pull %FULL_IMAGE_NAME%
echo docker run -d -p 8080:8080 --name wechat-api %FULL_IMAGE_NAME%
echo.
echo 🌐 访问地址: http://服务器IP:8080/swagger
echo.

REM 清理本地测试镜像（可选）
set /p cleanup="是否删除本地镜像以节省空间? (y/n): "
if /i "%cleanup%"=="y" (
    docker rmi %FULL_IMAGE_NAME%
    echo [√] 本地镜像已删除
)

echo.
echo 完成！
pause
