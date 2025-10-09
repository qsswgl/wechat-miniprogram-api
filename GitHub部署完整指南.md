# 🚀 GitHub仓库创建和部署完整指南

## 第一步：创建GitHub仓库

### 1.1 访问GitHub
打开浏览器，访问：https://github.com/new

### 1.2 填写仓库信息
- **Repository name**: `wechat-miniprogram-api`
- **Description**: `WeChat Mini-Program QR Code API with .NET 9 and Docker support`
- **Visibility**: ✅ Public（公开）
- **Initialize**: ❌ 不要勾选任何选项（README, .gitignore, LICENSE）

### 1.3 创建仓库
点击绿色的 **"Create repository"** 按钮

## 第二步：推送代码

### 2.1 使用自动脚本
```cmd
# 在项目目录运行
simple-push.bat
```

### 2.2 手动推送（如果脚本失败）
```cmd
# 初始化仓库
git init
git branch -M main

# 配置用户信息
git config user.name "qsswgl"  
git config user.email "qsswgl@users.noreply.github.com"

# 添加远程仓库
git remote add origin https://github.com/qsswgl/wechat-miniprogram-api.git

# 添加文件并提交
git add .
git commit -m "Initial commit: WeChat API with Docker support"

# 推送到GitHub
git push -u origin main
```

## 第三步：配置GitHub Secrets

### 3.1 访问仓库设置
访问：https://github.com/qsswgl/wechat-miniprogram-api/settings/secrets/actions

### 3.2 添加Docker Hub密码
1. 点击 **"New repository secret"**
2. Name: `DOCKER_PASSWORD`
3. Secret: `galaxy_s24`
4. 点击 **"Add secret"**

## 第四步：监控自动构建

### 4.1 查看GitHub Actions
访问：https://github.com/qsswgl/wechat-miniprogram-api/actions

### 4.2 构建状态
- ✅ **成功**: 绿色勾号，Docker镜像已推送
- ❌ **失败**: 红色叉号，查看日志排查问题
- 🟡 **进行中**: 黄色圆点，正在构建（约5-10分钟）

## 第五步：使用Docker镜像

### 5.1 拉取镜像
```bash
docker pull qsswgl/wechat-api:latest
```

### 5.2 运行容器
```bash
docker run -d -p 8080:8080 --name wechat-api qsswgl/wechat-api:latest
```

### 5.3 访问API
浏览器打开：http://localhost:8080/swagger

## 故障排除

### 问题1：推送失败 "Repository not found"
**解决方案**：
1. 确认GitHub仓库已创建
2. 仓库名称必须是 `wechat-miniprogram-api`
3. 仓库必须是Public（公开）

### 问题2：认证失败
**解决方案**：
1. 用户名：`qsswgl`
2. 密码：`qsswgl_5988856`
3. 如果启用2FA，需要使用Personal Access Token

### 问题3：GitHub Actions构建失败
**解决方案**：
1. 检查是否添加了 `DOCKER_PASSWORD` Secret
2. Secret值必须是 `galaxy_s24`
3. 查看Actions日志了解具体错误

### 问题4：中文乱码
**解决方案**：
1. PowerShell中运行：`[Console]::OutputEncoding = [System.Text.Encoding]::UTF8`
2. 或使用 `simple-push.bat` 脚本

## 验证部署成功

### 检查GitHub
- ✅ 代码已推送到仓库
- ✅ GitHub Actions显示绿色勾号
- ✅ 有Docker镜像构建日志

### 检查Docker Hub
访问：https://hub.docker.com/r/qsswgl/wechat-api
- ✅ 看到 `latest` 标签的镜像
- ✅ 显示最近推送时间

### 测试API
```bash
# 拉取并运行
docker pull qsswgl/wechat-api:latest
docker run -d -p 8080:8080 --name test-api qsswgl/wechat-api:latest

# 测试健康检查
curl http://localhost:8080/health

# 访问API文档
curl http://localhost:8080/swagger
```

## 完成！🎉

现在你已经拥有：
- ✅ GitHub源码仓库
- ✅ 自动化CI/CD流水线
- ✅ Docker Hub镜像仓库
- ✅ 全球可部署的容器化API

每次代码更新只需要：
```cmd
git add .
git commit -m "更新说明"
git push
```

GitHub Actions会自动构建新的Docker镜像！