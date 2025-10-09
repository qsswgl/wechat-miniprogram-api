# QSGL WeChat API - Docker 部署版

基于 .NET 9 的微信小程序二维码生成API，支持HTTP/3和SSL证书。

## 功能特性

- ✅ 微信小程序二维码生成
- ✅ SSL证书自动申请（Let's Encrypt + DNSPod）
- ✅ 多协议支持（HTTP/1.1, HTTP/2, HTTP/3）
- ✅ 静态文件服务（支持PNG/JPG/JPEG/WEBP）
- ✅ 跨域配置
- ✅ Docker容器化部署

## 快速部署

### 1. 准备工作

确保服务器上已安装：
- Docker
- Docker Compose

### 2. 部署步骤

```bash
# 克隆或上传项目文件到服务器
cd /path/to/project

# 确保证书文件存在（可选，如果没有证书可以先使用HTTP）
mkdir -p certificates
cp your-certificate.pfx certificates/qsgl.net.pfx

# 修改配置文件
cp appsettings.Docker.json appsettings.json
nano appsettings.json  # 修改微信AppId、AppSecret等配置

# 给部署脚本执行权限
chmod +x deploy.sh

# 执行部署
./deploy.sh
```

### 3. 配置文件说明

#### appsettings.json 主要配置项：

```json
{
  "WeChat": {
    "AppId": "你的微信AppId",
    "AppSecret": "你的微信AppSecret"
  },
  "DnsPod": {
    "Id": "你的DNSPod ID",
    "Key": "你的DNSPod Key"
  },
  "ServerConfig": {
    "Domain": "你的域名",
    "HttpsRedirectPort": 8081,
    "Ports": {
      "Http": 8080,
      "Https": 8081,
      "Http3": 8082,
      "HttpsCompat": 8083
    }
  }
}
```

## 访问地址

部署完成后可通过以下地址访问：

- **Swagger文档**: `https://your-domain:8083/swagger`
- **HTTP**: `http://your-domain:8080`
- **HTTPS**: `https://your-domain:8081`
- **HTTP/3**: `https://your-domain:8082`
- **HTTPS兼容**: `https://your-domain:8083`

## API 端点

### 生成二维码
```
GET /api/WeChat/CreateMiniProgramCode?DBName=xxx&goodsId=xxx&pagePath=xxx&accessToken=xxx
```

### 静态文件访问
```
GET /uploadall/filename.png
```

## 运维命令

```bash
# 查看运行状态
docker-compose ps

# 查看日志
docker-compose logs -f

# 停止服务
docker-compose down

# 重启服务
docker-compose restart

# 更新服务
git pull  # 或重新上传文件
./deploy.sh
```

## 目录结构

```
.
├── Dockerfile              # Docker构建文件
├── docker-compose.yml      # Docker编排配置
├── deploy.sh              # 部署脚本
├── appsettings.Docker.json # Docker环境配置模板
├── certificates/          # SSL证书目录（挂载）
├── wwwroot/uploadall/     # 上传文件目录（挂载）
└── ...其他源代码文件
```

## 故障排除

### 1. 端口被占用
```bash
# 检查端口占用
netstat -tulpn | grep :8080

# 修改docker-compose.yml中的端口映射
```

### 2. SSL证书问题
```bash
# 检查证书文件权限
ls -la certificates/

# 重新生成证书或使用HTTP访问测试
```

### 3. 容器启动失败
```bash
# 查看详细日志
docker-compose logs wechat-api

# 检查配置文件格式
docker-compose config
```