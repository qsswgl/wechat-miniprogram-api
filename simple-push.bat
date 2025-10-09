@echo off
chcp 65001 >nul
echo ===== GitHub 仓库推送脚本 =====
echo.

REM 直接推送（假设仓库已创建）
echo [1/3] 添加文件...
git add .

echo [2/3] 提交更改...
git commit -m "WeChat API with Docker support and GitHub Actions"

echo [3/3] 推送到GitHub...
git push -u origin main

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ✅ 推送成功！
    echo.
    echo 🔗 相关链接:
    echo - 仓库: https://github.com/qsswgl/wechat-miniprogram-api  
    echo - Actions: https://github.com/qsswgl/wechat-miniprogram-api/actions
    echo - Docker Hub: https://hub.docker.com/r/qsswgl/wechat-api
    echo.
    echo 📝 下一步：
    echo 1. 访问GitHub仓库设置页面
    echo 2. 添加Secret: DOCKER_PASSWORD = galaxy_s24
    echo 3. 等待GitHub Actions自动构建（约5-10分钟）
) else (
    echo.
    echo ❌ 推送失败！
    echo 请检查：
    echo 1. GitHub仓库是否已创建
    echo 2. 网络连接是否正常
    echo 3. Git凭据是否正确
)

echo.
pause