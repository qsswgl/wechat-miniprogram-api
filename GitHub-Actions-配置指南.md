# GitHub Actions 自动化部署配置指南

## 🔐 配置GitHub Secrets

为了让GitHub Actions能够自动推送镜像到Docker Hub，需要配置以下Secrets：

### 1. 访问GitHub仓库设置
1. 打开 https://github.com/qsswgl/wechat-miniprogram-api
2. 点击 **Settings** 选项卡
3. 在左侧菜单中选择 **Secrets and variables** > **Actions**

### 2. 添加Docker Hub密码
点击 **New repository secret** 按钮，添加：

- **Name**: `DOCKER_PASSWORD`
- **Secret**: `galaxy_s24`

### 3. 验证配置
确保Secrets页面显示：
- ✅ `DOCKER_PASSWORD` (Hidden)

## 🚀 自动化流程

### 推送代码触发构建
```bash
# 1. 运行提交脚本
push-to-github.bat

# 2. 代码推送后会自动触发GitHub Actions
# 3. Actions会自动构建Docker镜像并推送到Docker Hub
```

### 监控构建状态
- **Actions页面**: https://github.com/qsswgl/wechat-miniprogram-api/actions
- **Docker Hub**: https://hub.docker.com/r/qsswgl/wechat-api

## 📋 工作流程说明

GitHub Actions工作流 (`.github/workflows/docker-build.yml`) 会：

1. **触发条件**:
   - 推送到 `main` 或 `master` 分支
   - 手动触发 (workflow_dispatch)
   - Pull Request

2. **构建步骤**:
   - 检出代码
   - 设置Docker Buildx
   - 登录Docker Hub (使用Secrets)
   - 构建多架构镜像 (amd64, arm64)
   - 推送到Docker Hub

3. **镜像标签**:
   - `qsswgl/wechat-api:latest` (最新版本)
   - `qsswgl/wechat-api:main-sha123456` (带提交hash)

## 🐳 部署镜像

构建完成后，在任何服务器上使用：

```bash
# 拉取最新镜像
docker pull qsswgl/wechat-api:latest

# 运行容器
docker run -d -p 8080:8080 --name wechat-api qsswgl/wechat-api:latest

# 或使用Docker Compose
docker-compose -f docker-compose.hub.yml up -d
```

## 🔍 故障排除

### Actions构建失败
1. 检查Secrets是否正确配置
2. 查看Actions日志定位错误
3. 验证Dockerfile语法

### Docker Hub推送失败
1. 确认Docker Hub账号信息正确
2. 检查仓库权限设置
3. 验证网络连接

### 本地测试构建
```bash
# 本地测试Docker构建
docker build -t test-image .
docker run --rm -p 8080:8080 test-image
```

## 📝 更新镜像

每次代码更新后：
1. 提交代码到GitHub
2. Actions自动构建新镜像
3. 服务器上重新拉取部署

```bash
# 服务器更新部署
docker pull qsswgl/wechat-api:latest
docker stop wechat-api
docker rm wechat-api
docker run -d -p 8080:8080 --name wechat-api qsswgl/wechat-api:latest
```

## 🎯 最佳实践

1. **版本标签**: 使用具体版本而非latest用于生产环境
2. **健康检查**: 配置容器健康检查
3. **资源限制**: 设置内存和CPU限制
4. **日志管理**: 配置日志收集和轮转
5. **安全扫描**: 定期扫描镜像安全漏洞

---

配置完成后，每次代码推送都会自动构建并更新Docker Hub上的镜像！