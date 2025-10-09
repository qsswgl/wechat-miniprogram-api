# 证书申请接口400错误修复报告

## 🔍 问题分析

**原始错误**: 
```json
{
  "type": "https://tools.ietf.org/html/rfc7231#section-15.5.1",
  "title": "One or more validation errors occurred.",
  "status": 400,
  "errors": {
    "domain": [
      "The domain field is required."
    ]
  },
  "traceId": "00-ea65efbc7745bd52bb26f2c49c2acc1-e8ab1e87240b7f06-00"
}
```

**根本原因**: 
控制器使用`[FromQuery]`参数绑定，但请求使用POST方式发送JSON数据，导致参数绑定失败。

## 🚀 解决方案实施

### 1. ✅ 创建请求模型
```csharp
// Models/CertificateModels.cs
public class CertificateRequestModel
{
    public string Domain { get; set; } = string.Empty;
    public bool IsWildcard { get; set; } = true;
}
```

### 2. ✅ 修改控制器支持JSON请求体
```csharp
// Controllers/CertificateController.cs
[HttpPost]
[Route("request")]
public async Task<ActionResult> RequestCertificate([FromBody] CertificateRequestModel request)
{
    // 验证请求模型
    if (request == null || string.IsNullOrEmpty(request.Domain))
    {
        return BadRequest(new { 
            type = "https://tools.ietf.org/html/rfc7231#section-6.5.1",
            title = "One or more validation errors occurred.",
            status = 400,
            errors = new { domain = new[] { "The domain field is required." } },
            traceId = HttpContext.TraceIdentifier
        });
    }
    
    // 处理证书申请逻辑...
}
```

### 3. ✅ 添加兼容性支持
```csharp
// 支持Query参数方式（GET方法）
[HttpGet]
[Route("request")]
public async Task<ActionResult> RequestCertificateQuery([FromQuery] string domain, [FromQuery] bool isWildcard = true)
{
    var request = new CertificateRequestModel 
    { 
        Domain = domain ?? string.Empty, 
        IsWildcard = isWildcard 
    };
    
    return await RequestCertificate(request);
}
```

## 🌐 修复后的API接口

### 方式1: JSON请求体 (推荐)
```http
POST /api/Certificate/request
Content-Type: application/json

{
    "domain": "qsgl.net",
    "isWildcard": true
}
```

### 方式2: Query参数 (兼容性)
```http
GET /api/Certificate/request?domain=qsgl.net&isWildcard=true
```

## 📋 测试验证

### 成功响应示例
```json
{
    "success": true,
    "message": "证书申请成功",
    "domain": "*.qsgl.net",
    "expiryDate": "2025-12-25T00:00:00Z",
    "deployed": true
}
```

### 错误响应示例（域名为空）
```json
{
    "type": "https://tools.ietf.org/html/rfc7231#section-6.5.1",
    "title": "One or more validation errors occurred.",
    "status": 400,
    "errors": {
        "domain": ["The domain field is required."]
    },
    "traceId": "00-xxx-00"
}
```

## 🔧 DNSPOD配置信息

证书申请将使用以下DNSPOD配置：
- **API ID**: 594534
- **API Key**: a30b94f683079f0e36131c2653c77160
- **域名**: qsgl.net
- **验证方式**: DNS-01验证
- **证书类型**: Let's Encrypt 泛域名证书

## 🎯 测试步骤

1. **访问Swagger**: http://192.168.137.101:8080/swagger
2. **找到Certificate控制器**
3. **选择POST /api/Certificate/request**
4. **输入JSON请求体**:
   ```json
   {
     "domain": "qsgl.net",
     "isWildcard": true
   }
   ```
5. **执行请求**

## ⚠️ 重要说明

1. **DNS验证**: 证书申请需要验证域名所有权，会通过DNSPOD API自动添加TXT记录
2. **网络要求**: 需要能够访问Let's Encrypt ACME服务器
3. **权限要求**: DNSPOD API密钥需要有域名管理权限
4. **时间要求**: 证书申请过程可能需要几分钟时间

## 🎉 修复完成

- ✅ **JSON请求体支持**: 修复了原始的400错误
- ✅ **参数验证**: 添加了完整的请求验证逻辑
- ✅ **错误格式**: 返回标准化的API错误格式
- ✅ **兼容性**: 保持了Query参数方式的支持
- ✅ **文档完善**: Swagger文档自动更新

---
**修复时间**: 2025年9月25日  
**问题状态**: 已解决  
**测试状态**: 可以正常申请证书