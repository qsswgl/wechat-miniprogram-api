@echo off
chcp 65001 >nul
echo ===============================================
echo      QSGL API - 仅文件上传模式部署
echo ===============================================
echo.

set SERVER=root@123.57.93.200
set LOCAL_PATH=K:\QSGLAPI\wechatminiprogramapi
set REMOTE_PATH=/opt/qsgl-api

echo 🔧 [步骤 1/3] 本地清理和准备...
if exist "%LOCAL_PATH%\docker-deploy" (
    echo 删除本地 docker-deploy 目录...
    rmdir /s /q "%LOCAL_PATH%\docker-deploy"
)

if exist "%LOCAL_PATH%\qsgl-api-docker.zip" (
    echo 删除本地 zip 文件...
    del "%LOCAL_PATH%\qsgl-api-docker.zip"
)

echo ✅ 本地清理完成

echo.
echo 📤 [步骤 2/3] 上传项目文件（仅SFTP）...
echo 正在通过SCP上传到 %SERVER%:%REMOTE_PATH%...
scp -r "%LOCAL_PATH%" %SERVER%:%REMOTE_PATH%

if errorlevel 1 (
    echo ❌ 上传失败！
    pause
    exit /b 1
)
echo ✅ 文件上传完成

echo.
echo 📋 [步骤 3/3] 手动操作指引
echo.
echo ⚠️  由于服务器只允许SFTP连接，您需要通过其他方式执行以下命令：
echo.
echo 🔑 方式一：通过服务器控制面板的Web终端
echo 🔑 方式二：通过VNC/RDP远程桌面
echo 🔑 方式三：联系服务器管理员开启SSH权限
echo.
echo 📋 需要在服务器上执行的命令：
echo.
echo cd /opt/qsgl-api/wechatminiprogramapi
echo rm -rf docker-deploy/ ^|^| true
echo rm -f qsgl-api-docker.zip ^|^| true
echo docker system prune -f
echo docker-compose down
echo docker-compose build --no-cache --pull
echo docker-compose up -d
echo docker-compose ps
echo.
echo 💡 或者复制以下一行命令执行：
echo cd /opt/qsgl-api/wechatminiprogramapi ^&^& rm -rf docker-deploy/ ^&^& rm -f qsgl-api-docker.zip ^&^& docker system prune -f ^&^& docker-compose down ^&^& docker-compose build --no-cache --pull ^&^& docker-compose up -d ^&^& docker-compose ps

echo.
echo ===============================================
echo          📁 文件上传完成！
echo ===============================================
echo.
echo 🌐 部署完成后访问地址：
echo   HTTP:  http://123.57.93.200:8080/swagger
echo   HTTPS: https://123.57.93.200:8081/swagger

pause