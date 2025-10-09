# 证书申请"string"问题解决测试指南

## 🎯 问题现状
域名在JSON反序列化时被错误解析为字符串 `"string"` (长度6)，而不是期望的 `"qsgl.net"`。

## 🔍 诊断步骤

### 步骤1: 测试新的诊断端点
1. **访问Swagger**: http://192.168.137.101:8080/swagger
2. **找到Certificate控制器**，现在应该有3个端点：
   - `POST /api/Certificate/test` (JSON绑定测试)
   - `POST /api/Certificate/test-raw` (原始JSON测试)  
   - `POST /api/Certificate/request` (证书申请)

### 步骤2: 测试JSON绑定
1. **选择**: `POST /api/Certificate/test`
2. **输入**:
   ```json
   {
     "domain": "qsgl.net",
     "isWildcard": true
   }
   ```
3. **执行并观察**:
   - 是否返回 `DomainValue: "qsgl.net"` 
   - 还是返回 `DomainValue: "string"`？

### 步骤3: 测试原始JSON处理
1. **选择**: `POST /api/Certificate/test-raw`  
2. **使用相同JSON**
3. **对比结果**: 查看手动解析是否正确

## 🚀 可能的解决方案

### 解决方案A: 如果是Swagger UI问题
如果Swagger UI生成的默认值有问题，手动输入正确的JSON：

**正确格式**:
```json
{
  "domain": "qsgl.net",
  "isWildcard": true
}
```

**错误格式** (可能由Swagger自动生成):
```json
{
  "domain": "string", 
  "isWildcard": true
}
```

### 解决方案B: 如果是模型绑定问题
我已经添加了 `[example]` 标签和更严格的验证。

### 解决方案C: 如果是序列化配置问题  
可能需要配置 `System.Text.Json` 的选项。

## 📊 预期测试结果

### 诊断端点应该返回:
```json
{
  "success": true,
  "domainValue": "qsgl.net",
  "domainLength": 8,
  "domainType": "String", 
  "isWildcardValue": true,
  "message": "域名解析正常"
}
```

### 如果仍然错误:
```json
{
  "domainValue": "string",
  "domainLength": 6,
  "message": "警告：域名被错误解析为'string'"
}
```

## 🛠️ 故障排除

### 问题1: Swagger UI显示错误的示例值
**解决**: 手动清除示例框并输入正确JSON

### 问题2: 浏览器缓存问题  
**解决**: 刷新页面或使用无痕模式

### 问题3: JSON格式问题
**解决**: 确保JSON格式正确，没有多余的逗号或引号

## 📝 测试日志监控

在测试时，同时观察后台日志：
- 应该看到: `Domain: 'qsgl.net', IsWildcard: True, DomainLength: 8`
- 而不是: `Domain: 'string', IsWildcard: True, DomainLength: 6`

## 🎉 成功指标

当看到以下日志时，表示问题已解决：
```
info: 开始申请泛域名证书：qsgl.net
```
而不是：
```  
info: 开始申请泛域名证书：string
```

---
**现在请按照上述步骤在Swagger中进行测试，确定问题的具体原因！**