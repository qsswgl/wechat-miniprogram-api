@echo off
chcp 65001 >nul
echo ===== GitHub Actions 手动设置指南 =====
echo.

echo 🔍 检测到GitHub Actions未自动触发，这表示工作流文件可能未正确上传。
echo.
echo 📋 解决方案：手动创建GitHub Actions工作流
echo.

echo [步骤1] 访问GitHub仓库
echo 在浏览器中打开: https://github.com/qsswgl/wechat-miniprogram-api
echo.

echo [步骤2] 创建Actions工作流目录
echo 1. 点击 "Create new file"
echo 2. 在文件名框中输入: .github/workflows/docker-build.yml
echo    注意: 输入路径会自动创建目录结构
echo.

echo [步骤3] 复制工作流配置
echo 将以下内容复制到文件编辑器中:
echo.
echo ================== 工作流配置开始 ==================

type .github\workflows\docker-build.yml 2>nul || echo 文件不存在，请手动创建

echo ================== 工作流配置结束 ==================
echo.

echo [步骤4] 提交工作流文件
echo 1. 滚动到页面底部
echo 2. Commit message: "Add GitHub Actions workflow for Docker build"
echo 3. 点击 "Commit new file"
echo.

echo [步骤5] 配置Secrets
echo 1. 访问: https://github.com/qsswgl/wechat-miniprogram-api/settings/secrets/actions
echo 2. 点击 "New repository secret"
echo 3. Name: DOCKER_PASSWORD
echo 4. Secret: galaxy_s24
echo 5. 点击 "Add secret"
echo.

echo [步骤6] 上传项目文件
echo 由于网络问题无法直接推送，建议：
echo 1. 使用创建的 wechat-api-upload.zip
echo 2. 在GitHub仓库页面选择 "Upload files"
echo 3. 拖拽ZIP文件上传
echo 4. 或者逐个创建重要文件
echo.

echo 📁 关键文件清单（需要上传的文件）：
echo - Program.cs （主程序文件）
echo - WeChatMiniProgramAPI.csproj （项目文件）
echo - Dockerfile （Docker构建文件）
echo - Controllers/WeChatController.cs （控制器）
echo - appsettings.json （配置文件）
echo.

echo 🔄 触发构建的方法：
echo 1. 推送任何代码到main分支
echo 2. 在Actions页面手动运行工作流
echo 3. 创建Pull Request
echo.

pause