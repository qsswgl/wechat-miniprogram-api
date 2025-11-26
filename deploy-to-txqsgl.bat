@echo off
chcp 65001 >nul
echo ====================================================
echo    部署 WeChat API 到 tx.qsgl.net (Ubuntu)
echo ====================================================
echo.

set SERVER=tx.qsgl.net
set SSH_USER=root
set SSH_KEY=C:\Key\tx.qsgl.net_id_ed25519
set REMOTE_PATH=/root/wechat-api
set IMAGE_NAME=tx.qsgl.net:5000/wechat-api:latest

echo [1/6] 检查SSH密钥...
if not exist "%SSH_KEY%" (
    echo [错误] SSH密钥不存在: %SSH_KEY%
    pause
    exit /b 1
)
echo [OK] SSH密钥文件存在
echo.

echo [2/6] 保存镜像为tar文件...
docker save %IMAGE_NAME% -o wechat-api-image.tar
if errorlevel 1 (
    echo [错误] 镜像保存失败
    pause
    exit /b 1
)
echo [OK] 镜像已保存到 wechat-api-image.tar
echo.

echo [3/6] 上传镜像到服务器...
scp -i "%SSH_KEY%" wechat-api-image.tar %SSH_USER%@%SERVER%:/tmp/
if errorlevel 1 (
    echo [错误] 镜像上传失败
    pause
    exit /b 1
)
echo [OK] 镜像已上传
del wechat-api-image.tar
echo.

echo [4/6] 上传配置文件...
ssh -i "%SSH_KEY%" %SSH_USER%@%SERVER% "mkdir -p %REMOTE_PATH% /opt/scripts"
scp -i "%SSH_KEY%" docker-compose.production.yml %SSH_USER%@%SERVER%:%REMOTE_PATH%/
scp -i "%SSH_KEY%" .env.example %SSH_USER%@%SERVER%:%REMOTE_PATH%/.env
scp -i "%SSH_KEY%" scripts\monitor-wechat-api.sh %SSH_USER%@%SERVER%:/opt/scripts/
echo [OK] 配置文件已上传
echo.

echo [5/6] 在服务器上加载镜像并启动容器...
ssh -i "%SSH_KEY%" %SSH_USER%@%SERVER% "
echo '>>> 加载Docker镜像';
docker load -i /tmp/wechat-api-image.tar;
rm -f /tmp/wechat-api-image.tar;

echo '>>> 进入部署目录';
cd %REMOTE_PATH%;

echo '>>> 更新.env配置文件';
cat > .env << 'EOF'
IMAGE_REGISTRY=
IMAGE_NAME=%IMAGE_NAME%
IMAGE_TAG=
HTTP_PORT=8090
HTTPS_PORT=8092
UPLOAD_VOLUME=/data/wechat-uploadall
EOF

echo '>>> 停止旧容器';
docker-compose -f docker-compose.production.yml down || true;

echo '>>> 启动新容器';
docker-compose -f docker-compose.production.yml up -d;

echo '>>> 设置监控脚本权限';
chmod +x /opt/scripts/monitor-wechat-api.sh;

echo '>>> 等待容器启动';
sleep 8;

echo '>>> 检查容器状态';
docker ps --filter name=wechat-api --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}';

echo '>>> 查看容器日志(最近30行)';
docker logs --tail 30 wechat-api;
"
echo [OK] 容器已启动
echo.

echo [6/6] 验证部署...
timeout /t 5 /nobreak >nul
echo.
echo 尝试访问健康检查端点...
curl -k https://tx.qsgl.net:8092/api/health 2>nul
if errorlevel 1 (
    echo.
    echo [提示] 健康检查暂时无法访问,容器可能还在启动中
    echo        请稍后通过浏览器访问: https://tx.qsgl.net:8092/swagger
) else (
    echo.
    echo [OK] 健康检查通过!
)
echo.

echo ====================================================
echo    部署完成!
echo ====================================================
echo.
echo 访问地址:
echo   - API健康检查: https://tx.qsgl.net:8092/api/health
echo   - Swagger文档:  https://tx.qsgl.net:8092/swagger
echo   - API端点:      https://tx.qsgl.net:8092/api/wechat/...
echo.
echo 管理命令:
echo   - 查看日志: ssh -i "%SSH_KEY%" %SSH_USER%@%SERVER% "docker logs -f wechat-api"
echo   - 重启容器: ssh -i "%SSH_KEY%" %SSH_USER%@%SERVER% "cd %REMOTE_PATH% && docker-compose -f docker-compose.production.yml restart"
echo   - 停止容器: ssh -i "%SSH_KEY%" %SSH_USER%@%SERVER% "cd %REMOTE_PATH% && docker-compose -f docker-compose.production.yml down"
echo.
echo 监控脚本:
echo   - 测试监控: ssh -i "%SSH_KEY%" %SSH_USER%@%SERVER% "bash /opt/scripts/monitor-wechat-api.sh wechat-api"
echo   - 配置定时任务:
echo     crontab -e
echo     */5 * * * * bash /opt/scripts/monitor-wechat-api.sh wechat-api
echo.
pause
