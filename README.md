# 微信小程序二维码生成API

这是一个基于.NET 10开发的Web API项目，支持HTTP/3协议，用于生成微信小程序二维码。

## 功能特性

- 支持HTTP/3协议
- 微信小程序二维码生成
- 数据库存储过程调用
- 静态文件服务
- CORS跨域支持
- 完整的日志记录

## 主要接口

### 生成微信小程序二维码

**接口地址：** `GET /api/WeChat/CreateMiniProgramCode`

**请求参数：**
- `DBName` (string): 数据库名称
- `goodsId` (string): 商品ID
- `pagePath` (string): 小程序页面路径
- `uid` (string): 用户ID（可选）

**返回结果：**
```json
{
  "success": true,
  "url": "https://localhost:5001/uploadall/qrcode_20240925123456_12345.png"
}
```

## 配置说明

### 1. 数据库连接

在 `appsettings.json` 中配置数据库连接字符串：

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Data Source=.;Initial Catalog=YourDatabase;Integrated Security=true;TrustServerCertificate=true"
  }
}
```

### 2. HTTP/3 配置

HTTP/3已在 `appsettings.json` 中配置：

```json
{
  "Kestrel": {
    "Endpoints": {
      "Http3": {
        "Url": "https://localhost:5002",
        "Protocols": "Http3",
        "Certificate": {
          "Path": "testCert.pfx", 
          "Password": "testPassword"
        }
      }
    }
  }
}
```

### 3. 微信配置

在 `appsettings.json` 中配置微信相关信息：

```json
{
  "WeChat": {
    "AppId": "your_app_id",
    "AppSecret": "your_app_secret"
  }
}
```

## 数据库要求

需要创建存储过程 `GetAccessToken`，用于获取微信AccessToken：

```sql
CREATE PROCEDURE [dbo].[GetAccessToken]
    @Type NVARCHAR(50)
AS
BEGIN
    -- 根据Type参数返回对应的AccessToken
    -- 这里需要根据实际业务逻辑实现
    SELECT AccessToken FROM WeChatTokens WHERE Type = @Type AND ExpiresTime > GETDATE()
END
```

## 运行项目

1. 确保安装了.NET 10 SDK
2. 配置数据库连接字符串
3. 创建SSL证书（用于HTTP/3）
4. 运行项目：

```bash
dotnet run
```

项目将在以下地址启动：
- HTTP: http://localhost:5000
- HTTPS: https://localhost:5001
- HTTP/3: https://localhost:5002

## 依赖包

- Microsoft.AspNetCore.OpenApi
- Swashbuckle.AspNetCore
- Newtonsoft.Json
- System.Data.SqlClient
- Microsoft.AspNetCore.Cors

## 目录结构

```
WeChatMiniProgramAPI/
├── Controllers/
│   └── WeChatController.cs
├── Services/
│   ├── IDatabaseService.cs
│   ├── DatabaseService.cs
│   ├── IWeChatService.cs
│   └── WeChatService.cs
├── wwwroot/
│   └── uploadall/
├── appsettings.json
├── appsettings.Development.json
├── Program.cs
└── WeChatMiniProgramAPI.csproj
```

## 注意事项

1. 需要有效的SSL证书才能使用HTTP/3
2. 确保数据库中存在GetAccessToken存储过程
3. 微信AccessToken需要定期刷新，建议在数据库中实现token缓存机制
4. 生成的二维码图片保存在wwwroot/uploadall目录下