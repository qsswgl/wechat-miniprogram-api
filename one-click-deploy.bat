@echo off
chcp 65001 >nul
echo ===============================================
echo    QSGL WeChat API - 一键部署到Ubuntu服务器
echo ===============================================
echo.

:: 服务器配置
set SERVER=root@123.57.93.200
set LOCAL_PATH=K:\QSGLAPI\wechatminiprogramapi
set REMOTE_PATH=/opt/qsgl-api

echo 准备部署到: %SERVER%
echo 本地项目: %LOCAL_PATH%
echo 远程路径: %REMOTE_PATH%
echo.

echo [步骤 1/3] 上传项目文件...
echo 正在上传项目到Ubuntu服务器，请输入密码...
scp -r "%LOCAL_PATH%" %SERVER%:%REMOTE_PATH%

if errorlevel 1 (
    echo ❌ 上传失败！请检查网络连接和凭据
    pause
    exit /b 1
)
echo ✅ 项目文件上传完成

echo.
echo [步骤 2/3] 在服务器上安装Docker并部署...
echo 连接到服务器执行部署，请再次输入密码...

ssh %SERVER% "
echo '开始在Ubuntu服务器上部署...';
cd %REMOTE_PATH%;
echo '当前目录:' $(pwd);
echo '项目文件:';
ls -la;

echo '检查并安装Docker...';
if ! command -v docker &> /dev/null; then
    echo 'Docker未安装，正在安装...';
    apt-get update;
    apt-get install -y docker.io docker-compose;
    systemctl start docker;
    systemctl enable docker;
    echo 'Docker安装完成';
else
    echo 'Docker已安装，版本:';
    docker --version;
fi;

echo '设置执行权限...';
chmod +x deploy.sh;

echo '开始Docker构建和部署...';
./deploy.sh;

echo '';
echo '🎉 部署完成！';
echo '';
echo '服务访问地址：';
echo 'HTTP:  http://123.57.93.200:8080/swagger';
echo 'HTTPS: https://123.57.93.200:8081/swagger';
echo '';
echo '管理命令：';
echo '查看日志: docker-compose logs -f';
echo '重启服务: docker-compose restart';
echo '停止服务: docker-compose down';
"

if errorlevel 1 (
    echo.
    echo ⚠️  部署过程中可能出现错误
    echo 💡 您可以手动检查：
    echo ssh %SERVER%
    echo cd %REMOTE_PATH%
    echo ./deploy.sh
) else (
    echo.
    echo ===============================================
    echo          🎉 部署成功！ 🎉
    echo ===============================================
    echo.
    echo 🌐 访问地址：
    echo   HTTP:  http://123.57.93.200:8080/swagger
    echo   HTTPS: https://123.57.93.200:8081/swagger
    echo   HTTP/3: https://123.57.93.200:8082/swagger
    echo.
    echo 📱 微信小程序二维码API已就绪！
)

echo.
echo 按任意键退出...
pause >nul