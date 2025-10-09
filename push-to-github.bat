@echo off
chcp 65001 >nul
REM ===== 一键提交代码到GitHub并触发Docker自动构建 =====
echo.
echo ===== QSGL WeChat API GitHub 自动化部署 =====
echo.

REM 检查Git是否已安装
git --version >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [错误] 未检测到Git，请先安装Git
    echo 下载地址: https://git-scm.com/download/win
    pause
    exit /b 1
)

echo [√] Git已安装

REM 设置变量
set GITHUB_USERNAME=qsswgl
set GITHUB_REPO=wechat-miniprogram-api

echo.
echo GitHub信息:
echo - 用户名: %GITHUB_USERNAME%
echo - 仓库名: %GITHUB_REPO%
echo - 仓库URL: https://github.com/%GITHUB_USERNAME%/%GITHUB_REPO%
echo.

echo ============================================
echo 重要提示：GitHub仓库创建步骤
echo ============================================
echo 1. 打开浏览器访问: https://github.com/new
echo 2. 仓库名称填写: %GITHUB_REPO%
echo 3. 设置为Public（公开）
echo 4. 不要勾选任何初始化选项（README, .gitignore, LICENSE）
echo 5. 点击"Create repository"按钮
echo 6. 创建完成后按任意键继续...
echo ============================================
pause

REM 检查是否已经是Git仓库
if not exist ".git\" (
    echo [1/7] 初始化Git仓库...
    git init
    git branch -M main
) else (
    echo [1/7] Git仓库已存在，跳过初始化
)

REM 配置Git用户信息
echo [2/7] 配置Git用户信息...
git config user.name "%GITHUB_USERNAME%"
git config user.email "%GITHUB_USERNAME%@users.noreply.github.com"

REM 添加远程仓库
echo [3/7] 配置远程仓库...
git remote remove origin >nul 2>&1
git remote add origin https://github.com/%GITHUB_USERNAME%/%GITHUB_REPO%.git

REM 添加所有文件
echo [4/7] 添加文件到暂存区...
git add .

REM 提交更改
echo [5/7] 提交更改...
set commit_message=Initial commit: WeChat Mini-Program API with Docker support
git commit -m "%commit_message%"

REM 推送到GitHub
echo [6/7] 推送到GitHub...
echo.
echo 正在推送代码到GitHub...
echo 如果提示输入密码，请使用: qsswgl_5988856
echo 注意: 如果启用了2FA，需要使用Personal Access Token
echo.
git push -u origin main

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [错误] 推送失败！
    echo.
    echo 可能原因和解决方案：
    echo 1. 仓库不存在 - 请先访问 https://github.com/new 创建仓库
    echo 2. 仓库名称: %GITHUB_REPO%
    echo 3. 不要初始化README、.gitignore或LICENSE
    echo 4. 认证问题 - 检查用户名密码是否正确
    echo 5. 网络问题 - 检查网络连接
    echo.
    echo 创建仓库后重新运行此脚本
    echo.
    pause
    exit /b 1
)

echo [√] 代码推送成功！

REM 等待GitHub Actions
echo [7/7] 监控GitHub Actions构建状态...
echo.
echo ===== 部署成功! =====
echo.
echo 🎉 代码已成功推送到GitHub！
echo 🔄 GitHub Actions正在自动构建Docker镜像...
echo.
echo 📋 相关链接:
echo - 仓库地址: https://github.com/%GITHUB_USERNAME%/%GITHUB_REPO%
echo - Actions状态: https://github.com/%GITHUB_USERNAME%/%GITHUB_REPO%/actions
echo - Docker Hub: https://hub.docker.com/r/%GITHUB_USERNAME%/wechat-api
echo.
echo 📝 构建完成后，可使用以下命令部署:
echo docker pull %GITHUB_USERNAME%/wechat-api:latest
echo docker run -d -p 8080:8080 --name wechat-api %GITHUB_USERNAME%/wechat-api:latest
echo.
echo ⏳ 预计构建时间: 5-10分钟
echo 请访问Actions页面查看构建进度
echo.
pause