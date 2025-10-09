# 🚀 QSGL WeChat Mini-Program API

基于 .NET 9 构建的微信小程序二维码生成API，支持HTTP/3协议，具备自动SSL证书管理功能。

[![Docker Build](https://github.com/qsswgl/wechat-miniprogram-api/actions/workflows/docker-build.yml/badge.svg)](https://github.com/qsswgl/wechat-miniprogram-api/actions/workflows/docker-build.yml)
[![Docker Pulls](https://img.shields.io/docker/pulls/qsswgl/wechat-api)](https://hub.docker.com/r/qsswgl/wechat-api)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## ✨ 特性

- 🔥 **多协议支持**: HTTP/1.1, HTTP/2, HTTP/3
- 🔒 **自动SSL**: Let's Encrypt + DNSPod 自动证书申请和续期
- 📱 **微信集成**: 微信小程序二维码生成
- 🐳 **Docker化**: 支持容器化部署
- 🌐 **跨域支持**: 完整的CORS配置
- 📁 **静态文件**: 自动图片托管服务
- ⚡ **高性能**: Kestrel服务器优化
- 🔄 **CI/CD**: GitHub Actions自动构建

## 🔧 技术栈

- **.NET 9** - 最新.NET框架
- **ASP.NET Core** - Web API框架
- **Kestrel** - 高性能HTTP服务器
- **Let's Encrypt** - 免费SSL证书
- **DNSPod** - DNS解析和验证
- **Docker** - 容器化部署
- **Swagger** - API文档

## 🚀 快速开始

### 方式1: Docker Hub (推荐)

```bash
# 拉取镜像
docker pull qsswgl/wechat-api:latest

# 运行容器
docker run -d -p 8080:8080 --name wechat-api qsswgl/wechat-api:latest

# 访问API文档
curl http://localhost:8080/swagger
```

### 方式2: 一键部署脚本

**Windows:**
```cmd
# 下载并运行部署脚本
curl -O https://raw.githubusercontent.com/qsswgl/wechat-miniprogram-api/main/deploy-from-dockerhub.bat
deploy-from-dockerhub.bat
```

**Linux/Ubuntu:**
```bash
# 下载并运行部署脚本
wget https://raw.githubusercontent.com/qsswgl/wechat-miniprogram-api/main/deploy-from-dockerhub.sh
chmod +x deploy-from-dockerhub.sh
./deploy-from-dockerhub.sh
```

### 方式3: Docker Compose

```bash
# 使用Docker Compose部署
curl -O https://raw.githubusercontent.com/qsswgl/wechat-miniprogram-api/main/docker-compose.hub.yml
docker-compose -f docker-compose.hub.yml up -d
```

## 📋 API 接口

### 生成微信小程序二维码

```http
POST /api/wechat/create-miniprogram-code
Content-Type: application/json

{
  "scene": "user_id=123",
  "page": "pages/index/index", 
  "width": 430,
  "autoColor": true,
  "lineColor": {"r": 0, "g": 0, "b": 0}
}
```

**响应:**
```json
{
  "success": true,
  "message": "二维码生成成功",
  "imageUrl": "https://yourdomain.com:8083/uploadall/qrcode_20241009161822_63877.png"
}
```

### 其他接口

- `GET /swagger` - API文档
- `GET /health` - 健康检查
- `GET /uploadall/{filename}` - 静态文件访问

## 🔧 配置

### appsettings.json

```json
{
  "WeChat": {
    "AppId": "your_wechat_appid",
    "AppSecret": "your_wechat_appsecret"
  },
  "DnsPod": {
    "Id": "your_dnspod_id", 
    "Key": "your_dnspod_key"
  },
  "Certificate": {
    "Email": "admin@yourdomain.com",
    "AutoRenewDays": 30,
    "Domain": "yourdomain.com"
  }
}
```

## 🐳 Docker 部署

### 基本部署

```bash
# 基础HTTP模式
docker run -d -p 8080:8080 --name wechat-api qsswgl/wechat-api:latest
```

### 完整部署 (带卷挂载)

```bash
docker run -d \
  --name wechat-api \
  -p 8080:8080 \
  -v $(pwd)/uploadall:/app/wwwroot/uploadall \
  -v $(pwd)/certificates:/app/certificates \
  -e ASPNETCORE_ENVIRONMENT=Production \
  --restart unless-stopped \
  qsswgl/wechat-api:latest
```

### Docker Compose

```yaml
version: '3.8'
services:
  wechat-api:
    image: qsswgl/wechat-api:latest
    ports:
      - "8080:8080"
    volumes:
      - ./uploadall:/app/wwwroot/uploadall
      - ./certificates:/app/certificates
    environment:
      - ASPNETCORE_ENVIRONMENT=Production
    restart: unless-stopped
```

## 📁 项目结构

```
wechatminiprogramapi/
├── Controllers/
│   └── WeChatController.cs        # 微信API控制器
├── Properties/
├── wwwroot/
│   └── uploadall/                 # 上传文件目录
├── certificates/                  # SSL证书存储
├── .github/
│   └── workflows/
│       └── docker-build.yml       # GitHub Actions CI/CD
├── Program.cs                     # 应用入口点
├── Dockerfile                     # Docker构建文件
├── docker-compose.yml            # Docker编排文件
├── push-to-github.bat            # 一键提交脚本
└── appsettings.json              # 应用配置
```

## 🔒 端口和安全

### 端口配置

- **8080**: HTTP API端口
- **8081**: HTTPS (HTTP/1.1 + HTTP/2) 
- **8082**: HTTPS (HTTP/3)
- **8083**: HTTPS (兼容模式)

### SSL证书

- 支持 Let's Encrypt 自动证书
- DNSPod DNS-01 验证
- 自动续期 (默认30天前)
- 通配符证书支持

## 🚀 开发和部署

### 本地开发

```bash
# 克隆仓库
git clone https://github.com/qsswgl/wechat-miniprogram-api.git
cd wechat-miniprogram-api

# 安装依赖
dotnet restore

# 运行应用
dotnet run

# 访问 https://localhost:5001/swagger
```

### 自动化部署

项目使用GitHub Actions实现CI/CD：

1. **推送代码**: 代码推送到main分支自动触发构建
2. **自动构建**: GitHub Actions自动构建Docker镜像
3. **推送镜像**: 构建成功后推送到Docker Hub
4. **多架构**: 支持amd64和arm64架构

```bash
# 一键提交到GitHub (会触发自动构建)
push-to-github.bat
```

## 🔍 监控和维护

### 健康检查

```bash
# 检查容器状态
docker ps

# 查看应用日志
docker logs wechat-api

# API健康检查
curl http://localhost:8080/health
```

### 更新部署

```bash
# 拉取最新镜像并重新部署
docker pull qsswgl/wechat-api:latest
docker stop wechat-api && docker rm wechat-api
docker run -d -p 8080:8080 --name wechat-api qsswgl/wechat-api:latest
```

### 性能监控

- 内置请求时间统计
- 错误率监控  
- 资源使用情况
- 证书有效期监控

## 📊 使用统计

[![Docker Pulls](https://img.shields.io/docker/pulls/qsswgl/wechat-api)](https://hub.docker.com/r/qsswgl/wechat-api)
[![GitHub Stars](https://img.shields.io/github/stars/qsswgl/wechat-miniprogram-api)](https://github.com/qsswgl/wechat-miniprogram-api/stargazers)
[![GitHub Issues](https://img.shields.io/github/issues/qsswgl/wechat-miniprogram-api)](https://github.com/qsswgl/wechat-miniprogram-api/issues)

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

1. Fork 本仓库
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 打开 Pull Request

## 📄 许可证

本项目使用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 🔗 相关链接

- **GitHub**: https://github.com/qsswgl/wechat-miniprogram-api
- **Docker Hub**: https://hub.docker.com/r/qsswgl/wechat-api  
- **Actions**: https://github.com/qsswgl/wechat-miniprogram-api/actions
- **Issues**: https://github.com/qsswgl/wechat-miniprogram-api/issues

## 🙏 致谢

- [Let's Encrypt](https://letsencrypt.org/) - 免费SSL证书
- [DNSPod](https://www.dnspod.cn/) - DNS服务提供商
- [.NET](https://dotnet.microsoft.com/) - 开发平台
- [Docker](https://www.docker.com/) - 容器化平台

## 📞 支持

如有问题，请提交 [Issue](https://github.com/qsswgl/wechat-miniprogram-api/issues) 或联系维护者。

---

⭐ 如果这个项目对你有帮助，请给个星星！