# Docker 安装和使用指南

## Windows 系统安装Docker

### 方法1: Docker Desktop (推荐)
1. 访问 [Docker官网](https://www.docker.com/products/docker-desktop)
2. 下载 Docker Desktop for Windows
3. 运行安装程序并重启电脑
4. 启动Docker Desktop并等待完全启动

### 方法2: 命令行安装 (需要管理员权限)
```powershell
# 使用Chocolatey安装
Set-ExecutionPolicy Bypass -Scope Process -Force
iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
choco install docker-desktop

# 或使用winget安装
winget install Docker.DockerDesktop
```

## Ubuntu 系统安装Docker

```bash
# 更新包管理器
sudo apt update

# 安装Docker
sudo apt install docker.io docker-compose

# 启动Docker服务
sudo systemctl start docker
sudo systemctl enable docker

# 将当前用户添加到docker组 (可选)
sudo usermod -aG docker $USER
```

## 验证Docker安装

```bash
# 检查Docker版本
docker --version

# 检查Docker信息
docker info

# 运行测试容器
docker run hello-world
```

## 使用本项目的Docker镜像

### 方式1: 一键部署脚本

**Windows:**
```cmd
# 双击运行或在命令行执行
build-and-push-dockerhub.bat
```

**Linux/Ubuntu:**
```bash
# 给脚本执行权限
chmod +x deploy-from-dockerhub.sh

# 运行部署脚本
./deploy-from-dockerhub.sh
```

### 方式2: 手动命令

```bash
# 拉取镜像
docker pull qsswgl/wechat-api:latest

# 运行容器
docker run -d --name wechat-api -p 8080:8080 qsswgl/wechat-api:latest

# 访问API
# 浏览器打开: http://localhost:8080/swagger
```

### 方式3: Docker Compose

```bash
# 使用提供的docker-compose.hub.yml
docker-compose -f docker-compose.hub.yml up -d
```

## 常用Docker命令

```bash
# 查看运行中的容器
docker ps

# 查看所有容器
docker ps -a

# 查看容器日志
docker logs 容器名称

# 停止容器
docker stop 容器名称

# 删除容器
docker rm 容器名称

# 删除镜像
docker rmi 镜像名称

# 进入容器
docker exec -it 容器名称 /bin/bash
```

## 故障排除

### Docker Desktop无法启动
1. 检查Hyper-V是否启用
2. 检查虚拟化是否在BIOS中启用
3. 重启Docker Desktop服务

### 容器无法访问
1. 检查端口映射是否正确
2. 检查防火墙设置
3. 查看容器日志: `docker logs 容器名称`

### 权限问题 (Linux)
```bash
# 将用户添加到docker组
sudo usermod -aG docker $USER

# 重新登录或运行
newgrp docker
```

## 项目特定配置

### 环境变量
- `ASPNETCORE_ENVIRONMENT`: 设置为 Production
- `ASPNETCORE_URLS`: 默认 http://+:8080

### 卷挂载
- `./uploadall:/app/wwwroot/uploadall` - 上传文件存储
- `./certificates:/app/certificates` - SSL证书存储 (可选)

### 网络端口
- 8080: HTTP API端口
- 8081-8083: HTTPS端口 (需要证书)

## 生产环境部署建议

1. 使用具体版本标签而不是latest
2. 配置健康检查
3. 设置资源限制
4. 使用secrets管理敏感信息
5. 配置日志收集和监控