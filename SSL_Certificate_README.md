# SSL证书自动化管理功能

本项目已集成SSL证书自动申请、部署和续订功能，使用DNSPOD API进行DNS-01验证。

## 功能特性

- ✅ **自动申请Let's Encrypt SSL证书**
- ✅ **支持泛域名证书（*.qsgl.net）**
- ✅ **DNSPOD DNS API集成**
- ✅ **自动DNS-01验证**
- ✅ **证书自动部署**
- ✅ **证书到期自动续订**
- ✅ **证书状态监控**

## API接口

### 1. 申请SSL证书

```http
POST /api/Certificate/request?domain=qsgl.net&isWildcard=true
```

**参数：**
- `domain`: 域名（如：qsgl.net）
- `isWildcard`: 是否申请泛域名证书，默认true

**响应示例：**
```json
{
  "success": true,
  "message": "证书申请成功",
  "domain": "*.qsgl.net",
  "expiryDate": "2024-12-25T10:30:00Z",
  "deployed": true
}
```

### 2. 续订SSL证书

```http
POST /api/Certificate/renew?domain=qsgl.net
```

### 3. 获取证书信息

```http
GET /api/Certificate/info?domain=qsgl.net
```

**响应示例：**
```json
{
  "success": true,
  "certificate": {
    "domain": "qsgl.net",
    "issueDate": "2024-09-25T10:30:00Z",
    "expiryDate": "2024-12-24T10:30:00Z",
    "isWildcard": true,
    "issuer": "Let's Encrypt Authority X3",
    "daysUntilExpiry": 60,
    "needsRenewal": false
  }
}
```

### 4. 获取所有证书列表

```http
GET /api/Certificate/list
```

### 5. 自动续订即将过期的证书

```http
POST /api/Certificate/auto-renew
```

## 配置说明

### 1. DNSPOD API配置

在 `appsettings.json` 中配置DNSPOD API凭证：

```json
{
  "DnsPod": {
    "Id": "594534",
    "Key": "a30b94f683079f0e36131c2653c77160"
  }
}
```

### 2. 证书配置

```json
{
  "Certificate": {
    "Email": "admin@qsgl.net",
    "AutoRenewDays": 30,
    "Domain": "qsgl.net",
    "CheckIntervalHours": 24
  }
}
```

**配置说明：**
- `Email`: Let's Encrypt账户邮箱
- `AutoRenewDays`: 提前多少天自动续订证书
- `Domain`: 默认域名
- `CheckIntervalHours`: 自动检查证书状态的间隔（小时）

## 证书存储

证书文件存储在项目根目录的 `certificates` 文件夹中：

```
certificates/
├── account.key          # ACME账户密钥
├── qsgl.net.crt        # 证书文件（PEM格式）
├── qsgl.net.key        # 私钥文件（PEM格式）
├── qsgl.net.pfx        # PFX格式证书（用于IIS/.NET）
└── qsgl.net.info       # 证书信息文件
```

## 自动化流程

### 证书申请流程

1. **创建ACME账户** - 使用Let's Encrypt API
2. **创建证书订单** - 指定域名（支持泛域名）
3. **DNS-01验证** - 自动添加TXT记录到DNSPOD
4. **等待DNS传播** - 确保记录全球可查询
5. **验证挑战** - Let's Encrypt验证DNS记录
6. **生成证书** - 获取签发的SSL证书
7. **部署证书** - 保存为PFX格式，可直接用于.NET应用
8. **清理DNS记录** - 删除验证用的TXT记录

### 自动续订机制

- **后台服务监控** - 每24小时检查一次证书状态
- **提前30天续订** - 证书过期前30天自动续订
- **零停机更新** - 证书更新不影响服务运行
- **失败重试** - 续订失败时会在下次检查时重试

## 使用示例

### 1. 申请泛域名证书

```bash
curl -X POST "http://localhost:5050/api/Certificate/request?domain=qsgl.net&isWildcard=true"
```

### 2. 检查证书状态

```bash
curl "http://localhost:5050/api/Certificate/info?domain=qsgl.net"
```

### 3. 手动续订证书

```bash
curl -X POST "http://localhost:5050/api/Certificate/renew?domain=qsgl.net"
```

## 支持的域名

- **单域名证书**: `qsgl.net`
- **泛域名证书**: `*.qsgl.net`（推荐）
- **多域名支持**: 可为不同子域名申请独立证书

## 注意事项

1. **DNS传播时间** - DNS记录传播可能需要几分钟到几小时
2. **Let's Encrypt限制** - 每周最多申请20个证书
3. **DNSPOD API限制** - 请确保API密钥有足够的权限
4. **证书有效期** - Let's Encrypt证书有效期为90天
5. **网络要求** - 需要能访问Let's Encrypt API和DNSPOD API

## 故障排除

### 常见问题

1. **DNS验证失败**
   - 检查DNSPOD API凭证是否正确
   - 确认域名在DNSPOD中存在
   - 检查网络连接

2. **证书申请失败**
   - 检查Let's Encrypt API访问
   - 确认邮箱地址有效
   - 查看详细错误日志

3. **证书部署失败**
   - 检查文件系统权限
   - 确认证书存储目录可写

### 日志查看

应用程序会记录详细的证书操作日志，可以通过以下方式查看：

```bash
# 查看应用程序日志
tail -f logs/app.log

# 查看证书相关日志
grep "Certificate" logs/app.log
```

## 生产环境部署建议

1. **使用HTTPS** - 在生产环境中启用HTTPS
2. **API安全** - 为证书管理API添加身份验证
3. **监控告警** - 设置证书到期监控和告警
4. **备份策略** - 定期备份证书和私钥文件
5. **权限控制** - 限制证书文件的访问权限

这个SSL证书自动化系统将为您的qsgl.net域名提供完整的证书生命周期管理，确保网站始终使用有效的SSL证书。