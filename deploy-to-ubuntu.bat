@echo off
chcp 65001 >nul
echo ===============================================
echo    QSGL WeChat API - 一键部署到Ubuntu服务器
echo ===============================================
echo.

:: 服务器信息
set SERVER_IP=123.57.93.200
set SERVER_USER=root
set SERVER_PASS=galaxy_s24
set PROJECT_PATH=K:\QSGLAPI\wechatminiprogramapi
set REMOTE_PATH=/opt/qsgl-api

echo 服务器信息：
echo IP: %SERVER_IP%
echo 用户: %SERVER_USER%
echo 本地路径: %PROJECT_PATH%
echo 远程路径: %REMOTE_PATH%
echo.

echo [1/4] 检查本地项目文件...
if not exist "%PROJECT_PATH%" (
    echo 错误: 本地项目路径不存在！
    pause
    exit /b 1
)

if not exist "%PROJECT_PATH%\Dockerfile" (
    echo 错误: Docker文件不存在，请确保项目已准备完毕！
    pause
    exit /b 1
)

echo ✓ 本地项目文件检查完成

echo.
echo [2/4] 使用SCP上传项目到Ubuntu服务器...
echo 正在连接到 %SERVER_USER%@%SERVER_IP%...

:: 使用scp上传整个项目目录
scp -r -o StrictHostKeyChecking=no "%PROJECT_PATH%" %SERVER_USER%@%SERVER_IP%:%REMOTE_PATH%

if errorlevel 1 (
    echo 错误: 文件上传失败！
    echo 请检查网络连接和服务器配置
    pause
    exit /b 1
)

echo ✓ 项目文件上传完成

echo.
echo [3/4] 连接服务器并安装Docker（如需要）...

:: 创建临时SSH命令文件
echo #!/bin/bash > temp_deploy.sh
echo echo "开始在Ubuntu服务器上部署..." >> temp_deploy.sh
echo cd %REMOTE_PATH% >> temp_deploy.sh
echo echo "当前目录: $(pwd)" >> temp_deploy.sh
echo ls -la >> temp_deploy.sh
echo. >> temp_deploy.sh
echo echo "检查Docker安装..." >> temp_deploy.sh
echo if ! command -v docker ^&^> /dev/null; then >> temp_deploy.sh
echo     echo "Docker未安装，正在安装..." >> temp_deploy.sh
echo     apt-get update >> temp_deploy.sh
echo     apt-get install -y docker.io docker-compose >> temp_deploy.sh
echo     systemctl start docker >> temp_deploy.sh
echo     systemctl enable docker >> temp_deploy.sh
echo     echo "Docker安装完成" >> temp_deploy.sh
echo else >> temp_deploy.sh
echo     echo "Docker已安装" >> temp_deploy.sh
echo fi >> temp_deploy.sh
echo. >> temp_deploy.sh
echo echo "设置部署脚本权限..." >> temp_deploy.sh
echo chmod +x deploy.sh >> temp_deploy.sh
echo. >> temp_deploy.sh
echo echo "开始Docker部署..." >> temp_deploy.sh
echo ./deploy.sh >> temp_deploy.sh
echo. >> temp_deploy.sh
echo echo "部署完成！服务访问地址：" >> temp_deploy.sh
echo echo "HTTP:  http://%SERVER_IP%:8080/swagger" >> temp_deploy.sh
echo echo "HTTPS: https://%SERVER_IP%:8081/swagger" >> temp_deploy.sh
echo echo "查看日志: docker-compose logs -f" >> temp_deploy.sh

:: 上传并执行部署脚本
scp -o StrictHostKeyChecking=no temp_deploy.sh %SERVER_USER%@%SERVER_IP%:%REMOTE_PATH%/auto_deploy.sh

echo.
echo [4/4] 在服务器上执行自动部署...
ssh -o StrictHostKeyChecking=no %SERVER_USER%@%SERVER_IP% "chmod +x %REMOTE_PATH%/auto_deploy.sh && %REMOTE_PATH%/auto_deploy.sh"

:: 清理临时文件
del temp_deploy.sh

if errorlevel 1 (
    echo.
    echo 警告: 部署过程中出现错误，但文件已上传完成
    echo 您可以手动SSH到服务器检查：
    echo ssh %SERVER_USER%@%SERVER_IP%
    echo cd %REMOTE_PATH%
    echo ./deploy.sh
) else (
    echo.
    echo ===============================================
    echo          🎉 部署成功完成！ 🎉
    echo ===============================================
    echo.
    echo 服务访问地址：
    echo HTTP:  http://%SERVER_IP%:8080/swagger
    echo HTTPS: https://%SERVER_IP%:8081/swagger
    echo HTTP/3: https://%SERVER_IP%:8082/swagger
    echo HTTPS兼容: https://%SERVER_IP%:8083/swagger
    echo.
    echo 管理命令：
    echo 查看日志: ssh %SERVER_USER%@%SERVER_IP% "cd %REMOTE_PATH% && docker-compose logs -f"
    echo 重启服务: ssh %SERVER_USER%@%SERVER_IP% "cd %REMOTE_PATH% && docker-compose restart"
    echo 停止服务: ssh %SERVER_USER%@%SERVER_IP% "cd %REMOTE_PATH% && docker-compose down"
)

echo.
echo 按任意键退出...
pause >nul
