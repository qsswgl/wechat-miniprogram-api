@echo off
echo ===== 修复Swagger API文档显示问题 =====
echo.

set PRIVATE_REGISTRY=43.138.35.183:5000
set IMAGE_NAME=wechat-api-net8
set TAG=alpine-musl-ssl-swagger-fixed
set FULL_IMAGE=%PRIVATE_REGISTRY%/%IMAGE_NAME%:%TAG%

echo 修复内容:
echo - 添加了TestController测试控制器
echo - 改进了Swagger配置和文档
echo - 启用了XML文档生成
echo - 修复了API操作不显示的问题
echo.

echo [1/4] 重新构建镜像...
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

echo [3/4] 本地测试...
docker run --rm -d -p 8097:8080 -p 8098:8081 --name swagger-test %FULL_IMAGE%
echo 等待启动...
timeout /t 15 /nobreak >nul

echo 测试API端点:
curl -s -o nul -w "Health Check: %%{http_code}" http://localhost:8097/api/test/health 2>nul || echo 测试失败
echo.
curl -s -o nul -w "Swagger UI: %%{http_code}" http://localhost:8097/swagger/index.html 2>nul || echo Swagger失败
echo.

docker rm -f swagger-test 2>nul

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
echo # 等待启动并测试
echo sleep 15
echo curl http://43.138.35.183:8090/api/test/health
echo.
echo 新增的API端点:
echo - GET /api/test/health - 健康检查
echo - GET /api/test/info - 服务器信息  
echo - POST /api/test/echo - 消息回显测试
echo - GET /api/test/random - 随机数生成
echo.
pause