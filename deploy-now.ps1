# 一键部署脚本 - 部署最新镜像到生产服务器
# 使用方法: .\deploy-now.ps1

$ErrorActionPreference = "Stop"

Write-Host "=== 开始部署 WeChat API 到生产服务器 ===" -ForegroundColor Green

# 服务器配置
$SERVER = "43.138.35.183"
$SSH_KEY = "tx.qsgl.net_id_ed25519"
$REMOTE_USER = "root"

# Docker配置
$IMAGE_REGISTRY = "43.138.35.183:5000"
$IMAGE_NAME = "wechat-api-net8"
$IMAGE_TAG = "latest"

Write-Host "`n[1/5] 检查SSH密钥..." -ForegroundColor Cyan
if (-not (Test-Path $SSH_KEY)) {
    Write-Host "错误: SSH密钥文件不存在: $SSH_KEY" -ForegroundColor Red
    exit 1
}

Write-Host "[OK] SSH密钥存在" -ForegroundColor Green

Write-Host "`n[2/5] 上传Docker Compose配置文件..." -ForegroundColor Cyan
scp -i $SSH_KEY docker-compose.production.yml "${REMOTE_USER}@${SERVER}:/root/wechat-api/"
scp -i $SSH_KEY .env.example "${REMOTE_USER}@${SERVER}:/root/wechat-api/.env"
Write-Host "[OK] 配置文件已上传" -ForegroundColor Green

Write-Host "`n[3/5] 上传监控脚本..." -ForegroundColor Cyan
ssh -i $SSH_KEY "${REMOTE_USER}@${SERVER}" "mkdir -p /opt/scripts"
scp -i $SSH_KEY scripts/monitor-wechat-api.sh "${REMOTE_USER}@${SERVER}:/opt/scripts/"
ssh -i $SSH_KEY "${REMOTE_USER}@${SERVER}" "chmod +x /opt/scripts/monitor-wechat-api.sh"
Write-Host "[OK] 监控脚本已上传并设置权限" -ForegroundColor Green

Write-Host "`n[4/5] 在服务器上部署容器..." -ForegroundColor Cyan

$DEPLOY_SCRIPT = @"
#!/bin/bash
set -e

echo ">>> 进入部署目录"
cd /root/wechat-api

echo ">>> 确保.env文件存在"
if [ ! -f .env ]; then
    cp .env.example .env
fi

echo ">>> 拉取最新镜像"
docker pull ${IMAGE_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}

echo ">>> 停止并删除旧容器"
docker-compose -f docker-compose.production.yml down || true

echo ">>> 启动新容器"
docker-compose -f docker-compose.production.yml up -d

echo ">>> 等待容器启动"
sleep 5

echo ">>> 检查容器状态"
docker ps | grep wechat-api || echo "警告: 容器未运行"

echo ">>> 检查容器日志(最近20行)"
docker logs --tail 20 wechat-api || true

echo ">>> 部署完成"
"@

# 将脚本保存到临时文件
$TempScript = [System.IO.Path]::GetTempFileName()
$DEPLOY_SCRIPT | Out-File -FilePath $TempScript -Encoding UTF8

# 上传并执行
scp -i $SSH_KEY $TempScript "${REMOTE_USER}@${SERVER}:/tmp/deploy.sh"
ssh -i $SSH_KEY "${REMOTE_USER}@${SERVER}" "bash /tmp/deploy.sh"

# 清理临时文件
Remove-Item $TempScript

Write-Host "[OK] 容器部署完成" -ForegroundColor Green

Write-Host "`n[5/5] 验证部署..." -ForegroundColor Cyan

# 等待几秒让服务完全启动
Start-Sleep -Seconds 8

Write-Host "`n>>> 测试健康检查端点..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "https://43.138.35.183:8092/api/health" -SkipCertificateCheck -TimeoutSec 10
    Write-Host "[OK] 健康检查通过! 状态码: $($response.StatusCode)" -ForegroundColor Green
} catch {
    Write-Host "[警告] 健康检查失败,但这可能是正常的(容器仍在启动中)" -ForegroundColor Yellow
    Write-Host "错误: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host "`n>>> 获取容器运行状态..." -ForegroundColor Yellow
ssh -i $SSH_KEY "${REMOTE_USER}@${SERVER}" "docker ps --filter name=wechat-api --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"

Write-Host "`n=== 部署完成! ===" -ForegroundColor Green
Write-Host "`n访问地址:" -ForegroundColor Cyan
Write-Host "  - API健康检查: https://43.138.35.183:8092/api/health" -ForegroundColor White
Write-Host "  - Swagger文档: https://43.138.35.183:8092/swagger" -ForegroundColor White
Write-Host "`n监控:" -ForegroundColor Cyan
Write-Host "  - 查看日志: ssh -i $SSH_KEY ${REMOTE_USER}@${SERVER} 'docker logs -f wechat-api'" -ForegroundColor White
Write-Host "  - 监控脚本: /opt/scripts/monitor-wechat-api.sh" -ForegroundColor White
Write-Host "  - 手动测试: bash /opt/scripts/monitor-wechat-api.sh wechat-api" -ForegroundColor White
