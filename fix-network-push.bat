@echo off
chcp 65001 >nul
echo ===== GitHub网络连接问题解决方案 =====
echo.

echo [1/5] 检查网络连接...
ping -n 2 github.com >nul
if %ERRORLEVEL% NEQ 0 (
    echo ❌ GitHub无法访问，请检查网络连接
    pause
    exit /b 1
)
echo ✅ 网络连接正常

echo.
echo [2/5] 配置Git网络设置...
REM 增加Git超时时间
git config --global http.postBuffer 524288000
git config --global http.timeout 300

REM 禁用SSL验证（如果有SSL问题）
git config --global http.sslVerify false

REM 设置代理（如果需要）
REM git config --global http.proxy http://proxy.company.com:8080

echo ✅ Git网络配置完成

echo.
echo [3/5] 尝试使用SSH方式推送...
echo 检查是否有SSH密钥...

if not exist "%USERPROFILE%\.ssh\id_rsa" (
    echo 📝 生成SSH密钥...
    ssh-keygen -t rsa -b 4096 -C "qsswgl@users.noreply.github.com" -f "%USERPROFILE%\.ssh\id_rsa" -N ""
    echo.
    echo ⚠️  需要将SSH公钥添加到GitHub：
    echo 1. 复制以下公钥内容：
    echo.
    type "%USERPROFILE%\.ssh\id_rsa.pub"
    echo.
    echo 2. 访问 https://github.com/settings/keys
    echo 3. 点击"New SSH key"
    echo 4. 粘贴上面的公钥内容
    echo 5. 保存后按任意键继续...
    pause
    
    REM 更改为SSH远程地址
    git remote set-url origin git@github.com:qsswgl/wechat-miniprogram-api.git
) else (
    echo ✅ SSH密钥已存在
    git remote set-url origin git@github.com:qsswgl/wechat-miniprogram-api.git
)

echo.
echo [4/5] 推送到GitHub（SSH方式）...
git push -u origin main

if %ERRORLEVEL% EQU 0 (
    echo ✅ SSH推送成功！
    goto success
)

echo.
echo SSH推送失败，尝试HTTPS方式...
echo [5/5] 使用HTTPS重试...

REM 恢复HTTPS地址
git remote set-url origin https://github.com/qsswgl/wechat-miniprogram-api.git

REM 使用用户名密码认证
echo 正在尝试HTTPS推送...
git push -u origin main

if %ERRORLEVEL% EQU 0 (
    echo ✅ HTTPS推送成功！
    goto success
)

echo.
echo ❌ 所有方式都失败了，可能的解决方案：
echo.
echo 1. 网络代理问题：
echo    如果在公司网络，需要配置代理：
echo    git config --global http.proxy http://proxy地址:端口
echo.
echo 2. 防火墙问题：
echo    检查防火墙是否阻止了Git访问
echo.
echo 3. DNS问题：
echo    尝试更换DNS服务器（如8.8.8.8）
echo.
echo 4. 手动上传：
echo    将代码打包上传到GitHub网页版
echo.
goto end

:success
echo.
echo 🎉 推送成功！
echo.
echo 📋 下一步操作：
echo 1. 访问 https://github.com/qsswgl/wechat-miniprogram-api/settings/secrets/actions
echo 2. 添加Secret: DOCKER_PASSWORD = galaxy_s24
echo 3. 查看Actions构建状态: https://github.com/qsswgl/wechat-miniprogram-api/actions
echo.

:end
pause