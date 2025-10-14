@echo off
chcp 65001 >nul
echo ===== 简化版.NET 8 Docker构建 =====
echo.

REM 设置变量
set PRIVATE_REGISTRY=43.138.35.183:5000
set IMAGE_NAME=wechat-api-net8
set IMAGE_TAG=latest
set FULL_IMAGE_NAME=%PRIVATE_REGISTRY%/%IMAGE_NAME%:%IMAGE_TAG%

echo 镜像信息: %FULL_IMAGE_NAME%
echo.

echo [1/4] 检查Docker...
docker --version >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [错误] Docker未安装
    pause
    exit /b 1
)
echo [√] Docker已安装

echo.
echo [2/4] 尝试使用精简Dockerfile构建...
docker build -f Dockerfile.net8-simple -t %FULL_IMAGE_NAME% .
if %ERRORLEVEL% NEQ 0 (
    echo [错误] 精简版构建失败，尝试本地发布方式...
    goto local_publish
)

echo [√] Docker镜像构建成功
goto test_image

:local_publish
echo.
echo [备选方案] 使用本地发布 + 基础镜像...

REM 本地发布
echo 正在本地发布应用...
dotnet publish -c Release -r linux-x64 --self-contained true -p:PublishTrimmed=true -p:PublishSingleFile=true -o ./publish

if %ERRORLEVEL% NEQ 0 (
    echo [错误] 本地发布失败
    pause
    exit /b 1
)

REM 创建简单Dockerfile
echo 创建临时Dockerfile...
(
echo FROM scratch
echo WORKDIR /app
echo COPY ./publish/WeChatMiniProgramAPI /app/
echo COPY ./publish/appsettings*.json /app/
echo RUN mkdir -p /app/certificates /app/wwwroot/uploadall
echo EXPOSE 8080
echo ENV ASPNETCORE_ENVIRONMENT=Production
echo ENV ASPNETCORE_URLS=http://+:8080
echo ENTRYPOINT ["./WeChatMiniProgramAPI"]
) > Dockerfile.tmp

docker build -f Dockerfile.tmp -t %FULL_IMAGE_NAME% .
if %ERRORLEVEL% NEQ 0 (
    echo [错误] 临时构建也失败了
    pause
    exit /b 1
)

del Dockerfile.tmp
rmdir /s /q publish 2>nul

:test_image
echo.
echo [3/4] 测试镜像...
docker run --rm -d --name test-container -p 18080:8080 %FULL_IMAGE_NAME%
if %ERRORLEVEL% EQU 0 (
    echo [√] 测试容器启动成功
    timeout /t 5 /nobreak >nul
    docker stop test-container >nul 2>&1
) else (
    echo [警告] 测试启动失败，但镜像已构建
)

echo.
echo [4/4] 推送到私有仓库...
echo 注意: 请确保私有仓库 %PRIVATE_REGISTRY% 可访问
echo 如需要，请先运行: docker login %PRIVATE_REGISTRY%
echo.
pause

docker push %FULL_IMAGE_NAME%
if %ERRORLEVEL% NEQ 0 (
    echo [错误] 推送失败
    echo.
    echo 可能需要：
    echo 1. 配置不安全仓库: 在Docker设置中添加 %PRIVATE_REGISTRY%
    echo 2. 登录仓库: docker login %PRIVATE_REGISTRY%
    echo 3. 检查网络: ping 43.138.35.183
    echo.
    echo 镜像已在本地构建成功: %FULL_IMAGE_NAME%
    echo 可以手动推送或导出镜像文件
    echo.
    pause
    exit /b 1
)

echo.
echo ===== 部署成功！ =====
echo 镜像: %FULL_IMAGE_NAME%
echo 在目标服务器运行: docker run -d -p 8080:8080 %FULL_IMAGE_NAME%
echo.
pause