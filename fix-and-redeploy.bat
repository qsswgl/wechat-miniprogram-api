@echo off
chcp 65001 >nul
echo ===============================================
echo      QSGL API - 修复部署问题并重新部署
echo ===============================================
echo.

set SERVER=root@123.57.93.200
set LOCAL_PATH=K:\QSGLAPI\wechatminiprogramapi
set REMOTE_PATH=/opt/qsgl-api

echo 🔧 [步骤 1/4] 本地清理重复文件...
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
echo 📤 [步骤 2/4] 重新上传项目文件...
echo 正在上传到 %SERVER%:%REMOTE_PATH%...
scp -r "%LOCAL_PATH%" %SERVER%:%REMOTE_PATH%

if errorlevel 1 (
    echo ❌ 上传失败！
    pause
    exit /b 1
)
echo ✅ 文件上传完成

echo.
echo 🐳 [步骤 3/4] 在服务器上清理并重新构建...
ssh %SERVER% "
echo '清理服务器上的重复文件...';
cd %REMOTE_PATH%;
rm -rf docker-deploy/ || true;
rm -f qsgl-api-docker.zip || true;

echo '设置脚本权限...';
chmod +x *.sh;

echo '执行修复部署...';
./fix-deploy.sh;
"

if errorlevel 1 (
    echo ⚠️  部署过程可能有错误，但继续检查状态...
)

echo.
echo 🔍 [步骤 4/4] 验证部署状态...
ssh %SERVER% "cd %REMOTE_PATH% && docker-compose ps && echo '' && echo '=== 容器日志 (最后10行) ===' && docker-compose logs --tail=10"

echo.
echo ===============================================
echo          🎉 修复部署完成！ 🎉
echo ===============================================
echo.
echo 🌐 访问地址：
echo   HTTP:  http://123.57.93.200:8080/swagger
echo   HTTPS: https://123.57.93.200:8081/swagger
echo.
echo 📋 如果还有问题，可以SSH到服务器手动检查：
echo   ssh %SERVER%
echo   cd %REMOTE_PATH%
echo   docker-compose logs -f

pause