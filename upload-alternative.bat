@echo off
chcp 65001 >nul
echo ===== 网络问题替代上传方案 =====
echo.

echo 检测到GitHub连接问题，提供以下替代方案：
echo.

echo 方案1: 创建ZIP包手动上传
echo ================================
echo [1/3] 创建项目压缩包...

REM 创建临时目录
if exist "github-upload" rmdir /s /q "github-upload"
mkdir github-upload

REM 复制必要文件（排除大文件和临时文件）
xcopy *.cs github-upload\ /Y >nul 2>&1
xcopy *.csproj github-upload\ /Y >nul 2>&1
xcopy *.json github-upload\ /Y >nul 2>&1
xcopy *.md github-upload\ /Y >nul 2>&1
xcopy Dockerfile github-upload\ /Y >nul 2>&1
xcopy .dockerignore github-upload\ /Y >nul 2>&1
xcopy .gitignore github-upload\ /Y >nul 2>&1
xcopy LICENSE github-upload\ /Y >nul 2>&1

REM 复制目录
if exist Controllers xcopy Controllers github-upload\Controllers\ /E /I /Y >nul 2>&1
if exist Services xcopy Services github-upload\Services\ /E /I /Y >nul 2>&1
if exist Models xcopy Models github-upload\Models\ /E /I /Y >nul 2>&1
if exist Properties xcopy Properties github-upload\Properties\ /E /I /Y >nul 2>&1
if exist .github xcopy .github github-upload\.github\ /E /I /Y >nul 2>&1

REM 创建压缩包
powershell -Command "Compress-Archive -Path 'github-upload\*' -DestinationPath 'wechat-api-upload.zip' -Force"

if exist "wechat-api-upload.zip" (
    echo ✅ 压缩包创建成功: wechat-api-upload.zip
    echo.
    echo [2/3] 手动上传步骤:
    echo 1. 打开浏览器访问: https://github.com/qsswgl/wechat-miniprogram-api
    echo 2. 点击 "uploading an existing file" 
    echo 3. 拖拽 wechat-api-upload.zip 到上传区域
    echo 4. 填写提交信息: "Initial commit: WeChat API with Docker support"
    echo 5. 点击 "Commit changes"
    echo.
    
    echo [3/3] 配置GitHub Actions:
    echo 上传完成后访问: https://github.com/qsswgl/wechat-miniprogram-api/settings/secrets/actions
    echo 添加Secret: DOCKER_PASSWORD = galaxy_s24
    echo.
) else (
    echo ❌ 压缩包创建失败
)

echo.
echo 方案2: 使用GitHub Desktop
echo ==========================
echo 1. 下载GitHub Desktop: https://desktop.github.com/
echo 2. 登录GitHub账号
echo 3. 克隆仓库到本地
echo 4. 复制文件到克隆目录
echo 5. 使用GitHub Desktop提交和推送
echo.

echo 方案3: 网络配置检查
echo ==================
echo 可能的网络问题：
echo 1. 公司防火墙阻止HTTPS连接
echo 2. 代理设置问题
echo 3. DNS解析问题
echo.
echo 解决方案：
echo - 尝试切换网络（如手机热点）
echo - 配置代理: git config --global http.proxy http://proxy:port
echo - 更换DNS服务器到8.8.8.8
echo.

echo 文件已准备完毕！请选择合适的方案上传代码。
echo.
pause