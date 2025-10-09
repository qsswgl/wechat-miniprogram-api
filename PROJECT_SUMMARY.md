# .NET 10 微信小程序二维码API - HTTP/3支持项目

## 项目概述
已成功创建支持多HTTP协议的微信小程序二维码生成API，包含完整的SSL证书自动化管理功能。

## ✅ 已完成功能

### 1. 多协议HTTP支持
- **HTTP/1.1**: `http://127.0.0.1:8080` 
- **HTTP/2**: `https://127.0.0.1:8081` (HTTPS required)
- **HTTP/3**: `https://127.0.0.1:8082` (HTTPS required)
- 备用端口: `http://localhost:5051`, `https://localhost:5052`, `https://localhost:5053`

### 2. 核心API端点
- `GET /WeChat/info` - 获取API信息
- `POST /WeChat/generateQrCode` - 生成微信小程序二维码
- `GET /Certificate/status` - 查看证书状态
- `POST /Certificate/apply` - 申请新证书
- `POST /Certificate/renew` - 手动续订证书

### 3. SSL证书自动化
- **Let's Encrypt ACME 集成**: 使用 Certes 3.0.4 库
- **DNSPOD API 支持**: 
  - API ID: 594534
  - API Key: a30b94f683079f0e36131c2653c77160
- **DNS-01 验证**: 自动化域名验证
- **自动续订**: 后台服务每小时检查证书状态

### 4. 技术栈
- **.NET 10**: 最新版本框架
- **ASP.NET Core Web API**: RESTful API设计
- **Microsoft.Data.SqlClient 6.1.1**: 数据库连接
- **System.Text.Json**: JSON序列化 (从Newtonsoft.Json迁移)
- **Kestrel Server**: 多协议HTTP支持

## 🚀 部署状态

### 当前运行状态
```
info: Microsoft.Hosting.Lifetime[14]
      Now listening on: http://127.0.0.1:8080    # HTTP/1.1
info: Microsoft.Hosting.Lifetime[14]  
      Now listening on: https://127.0.0.1:8081   # HTTP/2
info: Microsoft.Hosting.Lifetime[14]
      Now listening on: https://127.0.0.1:8082   # HTTP/3
```

### 启动命令
```bash
cd k:\QSGLAPI\WeChatMiniProgramAPI
dotnet run --project "WeChatMiniProgramAPI.csproj"
```

## 📁 项目结构
```
WeChatMiniProgramAPI/
├── Controllers/
│   ├── WeChatController.cs      # 微信API控制器
│   └── CertificateController.cs # 证书管理控制器
├── Services/
│   ├── DatabaseService.cs      # 数据库服务
│   ├── DnsPodService.cs        # DNSPOD API服务
│   ├── CertificateService.cs   # ACME证书服务
│   └── CertificateRenewalService.cs # 证书续订后台服务
├── certificates/               # SSL证书存储目录
├── Program.cs                 # 应用程序入口点
├── appsettings.json          # 配置文件
└── WeChatMiniProgramAPI.csproj # 项目文件
```

## 🔧 核心配置

### Kestrel多协议配置
```csharp
builder.WebHost.ConfigureKestrel(serverOptions =>
{
    // HTTP/1.1 端口 8080
    serverOptions.Listen(System.Net.IPAddress.Loopback, 8080, options =>
    {
        options.Protocols = HttpProtocols.Http1;
    });

    // HTTP/2 端口 8081 (需要HTTPS)
    serverOptions.Listen(System.Net.IPAddress.Loopback, 8081, options =>
    {
        options.Protocols = HttpProtocols.Http2;
        options.UseHttps();
    });

    // HTTP/3 端口 8082 (需要HTTPS)
    serverOptions.Listen(System.Net.IPAddress.Loopback, 8082, options =>
    {
        options.Protocols = HttpProtocols.Http3;
        options.UseHttps();
    });
});
```

### DNSPOD配置
```json
{
  "DnsProviders": {
    "DnsPod": {
      "ApiId": "594534",
      "ApiKey": "a30b94f683079f0e36131c2653c77160",
      "BaseUrl": "https://dnsapi.cn"
    }
  }
}
```

## 🌐 API使用示例

### 1. 获取API信息
```bash
GET http://127.0.0.1:8080/WeChat/info
```

### 2. 生成微信小程序二维码
```bash
POST http://127.0.0.1:8080/WeChat/generateQrCode
Content-Type: application/json

{
  "scene": "test123",
  "width": 280,
  "page": "pages/index/index"
}
```

### 3. 查看证书状态
```bash
GET https://127.0.0.1:8081/Certificate/status
```

## 📋 后续工作建议

1. **生产环境部署**
   - 配置真实的微信小程序AppID和AppSecret
   - 设置生产数据库连接字符串
   - 配置域名解析到服务器IP

2. **SSL证书优化**
   - 测试DNSPOD API自动化申请流程
   - 验证证书自动续订功能
   - 配置证书存储路径

3. **性能优化**
   - 实施API限流
   - 添加缓存机制
   - 优化数据库查询

4. **监控和日志**
   - 集成Application Insights
   - 配置结构化日志
   - 添加健康检查端点

## 🔍 访问地址
- **Swagger UI**: http://127.0.0.1:8080/swagger
- **HTTP/1.1 API**: http://127.0.0.1:8080
- **HTTP/2 API**: https://127.0.0.1:8081  
- **HTTP/3 API**: https://127.0.0.1:8082

---
**项目完成时间**: 2025年9月25日
**框架版本**: .NET 10.0
**协议支持**: HTTP/1.1, HTTP/2, HTTP/3