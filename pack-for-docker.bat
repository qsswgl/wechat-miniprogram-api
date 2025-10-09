@echo off
echo 正在打包Docker部署文件...

cd /d K:\QSGLAPI\wechatminiprogramapi

:: 创建临时打包目录
if exist "docker-deploy" rmdir /s /q docker-deploy
mkdir docker-deploy

:: 复制必要的文件
copy Dockerfile docker-deploy\
copy docker-compose.yml docker-deploy\
copy deploy.sh docker-deploy\
copy appsettings.Docker.json docker-deploy\appsettings.json
copy README-Docker.md docker-deploy\
copy .dockerignore docker-deploy\
copy WeChatMiniProgramAPI.csproj docker-deploy\
copy Program.cs docker-deploy\

:: 复制目录
xcopy /E /I Controllers docker-deploy\Controllers
xcopy /E /I Services docker-deploy\Services
xcopy /E /I Models docker-deploy\Models
xcopy /E /I Properties docker-deploy\Properties

:: 创建必要的目录
mkdir docker-deploy\certificates
mkdir docker-deploy\wwwroot\uploadall

:: 复制证书文件（如果存在）
if exist certificates\*.pfx (
    copy certificates\*.pfx docker-deploy\certificates\
)

:: 打包为zip
powershell Compress-Archive -Path docker-deploy\* -DestinationPath qsgl-api-docker.zip -Force

echo 打包完成！文件保存为: qsgl-api-docker.zip
echo 现在可以将此zip文件上传到Ubuntu服务器

pause