@echo off
REM ===== QSGL WeChat API Docker Hub 构建部署脚本 =====
echo.
echo ===== QSGL WeChat API Docker Hub 构建部署脚本 =====
echo.

REM 检查Docker是否已安装
docker --version >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [错误] 未检测到Docker，请先安装Docker Desktop
    echo.
    echo 请按以下步骤操作：
    echo 1. 访问 https://www.docker.com/products/docker-desktop
    echo 2. 下载并安装Docker Desktop
    echo 3. 启动Docker Desktop并等待完全启动
    echo 4. 重新运行此脚本
    echo.
    pause
    exit /b 1
)

echo [√] Docker已安装
echo.

REM 设置镜像信息
set DOCKER_USERNAME=qsswgl
set DOCKER_PASSWORD=galaxy_s24
set IMAGE_NAME=wechat-api
set IMAGE_TAG=latest
set FULL_IMAGE_NAME=%DOCKER_USERNAME%/%IMAGE_NAME%:%IMAGE_TAG%

echo 镜像信息:
echo - Docker Hub用户: %DOCKER_USERNAME%
echo - 镜像名称: %IMAGE_NAME%
echo - 标签: %IMAGE_TAG%
echo - 完整镜像名: %FULL_IMAGE_NAME%
echo.

REM 登录Docker Hub
echo [1/4] 登录Docker Hub...
echo %DOCKER_PASSWORD%| docker login --username %DOCKER_USERNAME% --password-stdin
if %ERRORLEVEL% NEQ 0 (
    echo [错误] Docker Hub登录失败
    pause
    exit /b 1
)
echo [√] Docker Hub登录成功
echo.

REM 构建镜像
echo [2/4] 构建Docker镜像...
docker build -t %FULL_IMAGE_NAME% .
if %ERRORLEVEL% NEQ 0 (
    echo [错误] Docker镜像构建失败
    pause
    exit /b 1
)
echo [√] Docker镜像构建成功
echo.

REM 测试镜像
echo [3/4] 测试镜像...
docker run --rm -d --name test-wechat-api -p 18080:8080 %FULL_IMAGE_NAME%
timeout /t 10 /nobreak >nul
docker logs test-wechat-api
docker stop test-wechat-api >nul 2>&1
echo [√] 镜像测试完成
echo.

REM 推送镜像
echo [4/4] 推送镜像到Docker Hub...
docker push %FULL_IMAGE_NAME%
if %ERRORLEVEL% NEQ 0 (
    echo [错误] 镜像推送失败
    pause
    exit /b 1
)
echo [√] 镜像推送成功
echo.

REM 显示成功信息
echo ===== 部署成功! =====
echo.
echo Docker Hub镜像: %FULL_IMAGE_NAME%
echo.
echo 在任何安装了Docker的服务器上运行:
echo docker pull %FULL_IMAGE_NAME%
echo docker run -d -p 8080:8080 --name wechat-api %FULL_IMAGE_NAME%
echo.
echo 访问地址: http://服务器IP:8080/swagger
echo.

REM 清理本地镜像（可选）
set /p cleanup="是否删除本地镜像以节省空间? (y/n): "
if /i "%cleanup%"=="y" (
    docker rmi %FULL_IMAGE_NAME%
    echo [√] 本地镜像已删除
)

echo.
echo 完成！
pause