@echo off
echo === 生成修复后的部署包 ===

REM 删除旧文件
if exist docker-deploy rmdir /s /q docker-deploy
if exist qsgl-api-fixed.zip del qsgl-api-fixed.zip

REM 创建部署目录
mkdir docker-deploy

REM 复制必要文件
copy Dockerfile docker-deploy\
copy docker-compose.yml docker-deploy\
copy .dockerignore docker-deploy\
copy appsettings.json docker-deploy\
copy appsettings.Production.json docker-deploy\
copy *.csproj docker-deploy\
copy *.cs docker-deploy\
copy fix-container-restart.sh docker-deploy\

REM 复制Controllers目录
xcopy Controllers docker-deploy\Controllers\ /E /I

REM 复制Properties目录
if exist Properties xcopy Properties docker-deploy\Properties\ /E /I

REM 创建压缩包
powershell -Command "Compress-Archive -Path 'docker-deploy\*' -DestinationPath 'qsgl-api-fixed.zip' -Force"

echo.
echo === 修复包已生成: qsgl-api-fixed.zip ===
echo.
echo 请将此文件上传到服务器并执行以下命令：
echo.
echo unzip qsgl-api-fixed.zip
echo chmod +x fix-container-restart.sh
echo ./fix-container-restart.sh
echo.
pause