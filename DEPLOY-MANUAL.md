# 手动部署指令 - JSON序列化修复版本

## 在服务器 43.138.35.183 上执行以下命令：

### 1. 停止并清理旧容器
```bash
docker stop wechat-api || true
docker rm wechat-api || true
```

### 2. 拉取新镜像（JSON序列化修复版）
```bash
docker pull 43.138.35.183:5000/wechat-api-net8:alpine-musl-json-fixed
```

### 3. 启动新容器
```bash
docker run -d \
  --name wechat-api \
  --restart unless-stopped \
  -p 8090:8080 \
  -p 8091:8081 \
  -p 8092:8082 \
  -v /etc/localtime:/etc/localtime:ro \
  --memory=512m \
  --cpus="1" \
  43.138.35.183:5000/wechat-api-net8:alpine-musl-json-fixed
```

### 4. 验证部署
```bash
# 检查容器状态
docker ps | grep wechat-api

# 查看容器日志
docker logs wechat-api --tail 30

# 测试API访问
curl -k http://localhost:8090/swagger/index.html
curl -k https://localhost:8091/swagger/index.html
```

## 访问地址：
- HTTP: http://43.138.35.183:8090/swagger
- HTTPS: https://43.138.35.183:8091/swagger  
- HTTPS2: https://43.138.35.183:8092/swagger

## 修复内容：
1. 启用了JSON序列化反射支持 (JsonSerializerIsReflectionEnabledByDefault=true)
2. 配置了DefaultJsonTypeInfoResolver支持反射序列化
3. 增强了Swagger/OpenAPI文档生成配置
4. 解决了.NET 8 AOT/Trimming导致的JSON序列化问题

## 预期修复的问题：
- Swagger文档生成500错误
- "Failed to load API definition"错误
- JSON序列化反射禁用导致的API功能异常