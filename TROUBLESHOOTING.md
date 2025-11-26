# WeChat API 故障排查指南

本指南覆盖生产环境常见问题与排查步骤，适用于容器名称 `wechat-api`、HTTPS 端口 8092。

## 1. 快速体检（推荐）

优先运行自动诊断脚本：

- Linux 服务器：`bash scripts/diagnose-wechat-api.sh`
- 若输出中显示 RestartPolicy=none，需设置自动重启策略（见第4节）

## 2. 核心检查清单

- 容器状态与端口
  - `docker ps --filter name=wechat-api`
  - `ss -tulpen | grep -E ':(8090|8092)\s'`
- 健康检查
  - `docker inspect -f "{{ if .State.Health }}{{ .State.Health.Status }}{{ else }}N/A{{ end }}" wechat-api`
  - 容器内：`docker exec wechat-api curl -kfsS https://localhost:8082/api/health`
- 日志
  - `docker logs --tail 200 wechat-api`
- 数据卷与权限
  - 上传目录推荐宿主 `/data/wechat-uploadall` 挂载到容器 `/app/wwwroot/uploadall`
  - 权限：`chown 1001:1001 /data/wechat-uploadall; chmod 755 /data/wechat-uploadall`
- 证书
  - 采用内置证书（PFX）并由 Kestrel 使用，确认 appsettings.Production.json 的证书路径与密码

## 3. 常见问题与修复

- 问题：8092 无法访问
  - 检查容器是否运行与端口映射：`docker ps`
  - 宿主防火墙：放行 8092
  - 内部 HTTPS 监听：容器内 `curl -k https://localhost:8082/swagger/`
- 问题：容器反复退出或未自动拉起
  - 设置重启策略：`docker update --restart unless-stopped wechat-api`
  - 查看最后日志：`docker logs wechat-api`
- 问题：生成二维码报错/图片未保存
  - 查看 `/app/wwwroot/uploadall` 写入权限
  - 若使用绑定卷，宿主目录需赋权给 UID 1001
- 问题：访问 token 过期（日志 42001/40001）
  - 属于业务层问题，建议实现稳定 token 管理（缓存/刷新/稳定令牌接口）

## 4. 设置自动重启策略

- 单次修正：`docker update --restart unless-stopped wechat-api`
- 新部署建议：Compose 中配置 `restart: unless-stopped`

## 5. 健康检查与自愈

- Dockerfile 已添加 `HEALTHCHECK`，并在 Compose 中配置健康检查
- 结合 `scripts/monitor-wechat-api.sh` 与 cron 可实现自愈：
  - 基础配置：`*/5 * * * * /bin/bash /opt/wechat-api/scripts/monitor-wechat-api.sh >> /var/log/cron.log 2>&1`
  - 启用邮件告警：配置环境变量后执行（参见下节）

### 配置邮件告警

监控脚本支持通过 SMTP 发送告警邮件：

1. 复制配置模板：
   ```bash
   cp /opt/wechat-api/scripts/monitor-config.env.example /opt/wechat-api/scripts/monitor-config.env
   ```

2. 编辑 `monitor-config.env` 填写实际配置：
   ```bash
   ALERT_EMAIL_ENABLED=true
   SMTP_SERVER=smtp.139.com
   SMTP_PORT=25
   SMTP_USER=your-email@139.com
   SMTP_PASS=your-auth-code
   ALERT_EMAIL_TO=admin@example.com
   ```

3. 更新 crontab 引用环境变量：
   ```bash
   */5 * * * * source /opt/wechat-api/scripts/monitor-config.env && /bin/bash /opt/wechat-api/scripts/monitor-wechat-api.sh >> /var/log/wechat-api-monitor.cron.log 2>&1
   ```

**注意**：
- 139邮箱需使用授权码而非密码
- 确保服务器能访问 SMTP 服务器（检查防火墙/安全组）
- Windows 环境可使用 `monitor-wechat-api.ps1` 并设置对应环境变量

## 6. 使用 Docker Compose 部署

- 生产示例见 `docker-compose.production.yml`
- 启动：`docker compose -f docker-compose.production.yml up -d`
- 更新镜像：`docker compose -f docker-compose.production.yml pull && docker compose -f docker-compose.production.yml up -d`

## 7. 收集信息用于支持

- `docker inspect wechat-api > diagnose-wechat-api.json`
- `docker logs --since 1h wechat-api > logs.txt`
- 通过自动诊断脚本完成一站式采集
