# 修复的GitHub自动化部署脚本
Write-Host "🚀 开始自动化GitHub部署流程..." -ForegroundColor Cyan

# 参数设置
$RepoName = "wechat-miniprogram-api"
$Username = "qsswgl" 
$Password = "qsswgl_5988856"
$Description = "WeChat Mini Program API - .NET 8 Docker部署版本"

# 设置项目目录
$ProjectDir = "K:\QSGLAPI\WeChatMiniProgramAPI"
Set-Location $ProjectDir

Write-Host "📁 当前工作目录: $ProjectDir" -ForegroundColor Green

# 1. 初始化Git仓库
Write-Host "`n1️⃣ 初始化Git仓库..." -ForegroundColor Yellow
if (!(Test-Path ".git")) {
    git init
    Write-Host "✅ Git仓库已初始化" -ForegroundColor Green
} else {
    Write-Host "✅ Git仓库已存在" -ForegroundColor Green
}

# 2. 创建.gitignore文件
Write-Host "`n2️⃣ 创建.gitignore文件..." -ForegroundColor Yellow
@'
# Build results
[Dd]ebug/
[Dd]ebugPublic/
[Rr]elease/
[Rr]eleases/
x64/
x86/
build/
bld/
[Bb]in/
[Oo]bj/
[Oo]ut/
msbuild.log
*.log

# Visual Studio
.vs/
*.user
*.suo
*.userosscache
*.sln.docstates

# .NET Core
project.lock.json
project.fragment.lock.json
artifacts/
**/Properties/launchSettings.json

# Docker
.dockerignore

# SSH Keys and Certificates
*.pem
*.pfx
*.key
*_rsa*
*_ed25519*
ssh_*
tx.qsgl.net_*
certificates/
*.crt

# Configuration files
appsettings.Production.json
appsettings.Local.json

# Temporary files
*.tmp
*.temp
deploy-*.sh
deploy-*.ps1
fix-*.ps1

# IDE
.vscode/
.idea/
'@ | Out-File -FilePath ".gitignore" -Encoding UTF8

Write-Host "✅ .gitignore文件已创建" -ForegroundColor Green

# 3. 创建README.md
Write-Host "`n3️⃣ 创建README.md..." -ForegroundColor Yellow
@'
# WeChat Mini Program API

🚀 基于.NET 8的微信小程序API服务，支持Docker部署和SSL证书

## 📋 项目特性

- ✅ **.NET 8** - 最新LTS框架
- ✅ **Docker部署** - Alpine Linux容器化
- ✅ **SSL支持** - HTTPS安全连接
- ✅ **Swagger文档** - API文档自动生成
- ✅ **微信API** - 小程序二维码生成
- ✅ **高性能** - 优化的JSON序列化
- ✅ **健康检查** - 应用状态监控

## 🛠️ 技术栈

- **框架**: ASP.NET Core 8.0
- **容器**: Docker + Alpine Linux
- **数据库**: SQL Server (可配置)
- **文档**: Swagger/OpenAPI
- **部署**: 私有Docker Registry

## 🚀 快速开始

### 本地开发

```bash
# 克隆项目
git clone https://github.com/qsswgl/wechat-miniprogram-api.git
cd wechat-miniprogram-api

# 还原依赖
dotnet restore

# 运行项目
dotnet run
```

### Docker部署

```bash
# 构建镜像
docker build -f Dockerfile.alpine-musl -t wechat-api .

# 运行容器
docker run -d --name wechat-api \
  -p 8090:8080 \
  -p 8091:8081 \
  -p 8092:8082 \
  wechat-api
```

## 📚 API文档

部署完成后访问 Swagger 文档：
- HTTP: http://your-server:8090/swagger
- HTTPS: https://your-server:8091/swagger

## 🔧 配置说明

### 端口配置
- **8090**: HTTP端口
- **8091**: HTTPS端口（主）
- **8092**: HTTPS端口（备用）

## 📦 项目结构

```
├── Controllers/          # API控制器
├── Services/            # 业务逻辑服务
├── Models/              # 数据模型
├── Dockerfile.alpine-musl  # Docker构建文件
├── appsettings.json     # 应用配置
└── Program.cs           # 应用入口
```

## 🚀 部署到生产环境

1. **配置SSL证书**
2. **设置环境变量**  
3. **运行Docker容器**
4. **配置反向代理**（可选）

## 👥 作者

- **qsswgl** - 初始开发 - [GitHub](https://github.com/qsswgl)

## 🆘 支持

如有问题，请创建 [Issue](https://github.com/qsswgl/wechat-miniprogram-api/issues)
'@ | Out-File -FilePath "README.md" -Encoding UTF8

Write-Host "✅ README.md文件已创建" -ForegroundColor Green

# 4. 添加文件到Git
Write-Host "`n4️⃣ 添加文件到Git..." -ForegroundColor Yellow
git add .
Write-Host "✅ 所有文件已添加到Git暂存区" -ForegroundColor Green

# 5. 提交更改
Write-Host "`n5️⃣ 提交更改..." -ForegroundColor Yellow
git commit -m "🎉 Initial commit: WeChat Mini Program API

✨ Features:
- .NET 8 ASP.NET Core API
- Docker containerization with Alpine Linux
- SSL/HTTPS support with certificates
- Swagger/OpenAPI documentation
- WeChat Mini Program QR code generation
- Health check endpoints
- JSON serialization optimization
- Multi-port configuration (8090/8091/8092)

🚀 Deployment:
- Docker private registry support
- Production-ready configuration
- Container resource optimization
- Security best practices"

Write-Host "✅ 更改已提交" -ForegroundColor Green

# 6. 设置远程仓库
Write-Host "`n6️⃣ 设置GitHub远程仓库..." -ForegroundColor Yellow

# 构建GitHub仓库URL
$RepoUrl = "https://${Username}:${Password}@github.com/${Username}/${RepoName}.git"

Write-Host "正在添加远程仓库..." -ForegroundColor Yellow
git remote remove origin 2>$null
git remote add origin $RepoUrl

# 7. 推送到GitHub
Write-Host "`n7️⃣ 推送到GitHub..." -ForegroundColor Yellow
Write-Host "正在推送到远程仓库..." -ForegroundColor Yellow

# 确保使用main分支
git branch -M main

try {
    git push -u origin main
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "🎉 代码推送成功！" -ForegroundColor Green
        $success = $true
    } else {
        Write-Host "❌ 推送失败，可能需要先在GitHub创建仓库" -ForegroundColor Red
        $success = $false
    }
} catch {
    Write-Host "❌ 推送失败: $($_.Exception.Message)" -ForegroundColor Red
    $success = $false
}

# 8. 清理敏感信息
Write-Host "`n8️⃣ 清理敏感信息..." -ForegroundColor Yellow
git remote set-url origin "https://github.com/${Username}/${RepoName}.git"
Write-Host "✅ 远程URL已清理" -ForegroundColor Green

# 9. 显示结果
Write-Host "`n📊 部署结果总结:" -ForegroundColor Cyan
Write-Host "✅ Git仓库: 已初始化" -ForegroundColor Green
Write-Host "✅ 项目文件: 已提交" -ForegroundColor Green  
Write-Host "✅ README.md: 已创建" -ForegroundColor Green
Write-Host "✅ .gitignore: 已配置" -ForegroundColor Green

if ($success) {
    Write-Host "✅ GitHub推送: 成功" -ForegroundColor Green
    Write-Host "`n🌐 GitHub仓库地址:" -ForegroundColor Cyan
    Write-Host "   https://github.com/$Username/$RepoName" -ForegroundColor White
} else {
    Write-Host "❌ GitHub推送: 失败" -ForegroundColor Red
    Write-Host "`n🔧 手动操作步骤:" -ForegroundColor Yellow
    Write-Host "1. 访问 https://github.com/new" -ForegroundColor White
    Write-Host "2. 创建名为 '$RepoName' 的仓库" -ForegroundColor White
    Write-Host "3. 执行: git push -u origin main" -ForegroundColor White
}

Write-Host "`n🎉 GitHub部署流程完成！" -ForegroundColor Green