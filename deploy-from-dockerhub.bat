@echo off
REM QSGL WeChat API - 从Docker Hub快速部署 (Windows版本)

echo ===== 从Docker Hub部署QSGL WeChat API =====
echo.

REM 检查Docker
docker --version >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [错误] Docker未安装或未运行
    echo 请先安装并启动Docker Desktop
    pause
    exit /b 1
)

echo [√] Docker环境检查通过

REM 设置变量
set IMAGE_NAME=qsswgl/wechat-api:latest
set CONTAINER_NAME=qsgl-wechat-api

REM 停止现有容器
echo 停止现有容器...
docker stop %CONTAINER_NAME% >nul 2>&1
docker rm %CONTAINER_NAME% >nul 2>&1

REM 拉取最新镜像
echo 拉取最新镜像...
docker pull %IMAGE_NAME%
if %ERRORLEVEL% NEQ 0 (
    echo [错误] 镜像拉取失败
    pause
    exit /b 1
)
echo [√] 镜像拉取成功

REM 创建目录
if not exist "uploadall" mkdir uploadall

REM 启动容器
echo 启动容器...
docker run -d --name %CONTAINER_NAME% -p 8080:8080 -v "%cd%\uploadall:/app/wwwroot/uploadall" -e ASPNETCORE_ENVIRONMENT=Production --restart unless-stopped %IMAGE_NAME%

if %ERRORLEVEL% NEQ 0 (
    echo [错误] 容器启动失败
    pause
    exit /b 1
)

REM 等待启动
echo 等待服务启动...
timeout /t 10 /nobreak >nul

REM 检查状态
docker ps | findstr %CONTAINER_NAME% >nul
if %ERRORLEVEL% EQU 0 (
    echo [√] 容器启动成功
    echo.
    echo ===== 部署完成 =====
    echo HTTP访问: http://localhost:8080/swagger
    echo.
    echo 管理命令:
    echo 查看日志: docker logs %CONTAINER_NAME%
    echo 停止服务: docker stop %CONTAINER_NAME%
    echo 重启服务: docker restart %CONTAINER_NAME%
) else (
    echo [错误] 容器启动失败，查看日志:
    docker logs %CONTAINER_NAME%
)

echo.
pause