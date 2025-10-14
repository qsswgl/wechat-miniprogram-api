# PowerShell部署脚本 - 用于远程部署到Ubuntu服务器
# 使用Docker CLI远程连接部署

param(
    [string]$ServerIP = "43.138.35.183"
)

Write-Host "开始部署JSON序列化修复版本到服务器 $ServerIP..." -ForegroundColor Green

try {
    # 设置Docker环境变量连接到远程Docker daemon (如果配置了)
    # 或者使用docker context (如果已配置)
    
    Write-Host "检查本地Docker连接..." -ForegroundColor Yellow
    docker version
    
    Write-Host "停止并删除现有容器..." -ForegroundColor Yellow
    docker -H tcp://$ServerIP`:2376 stop wechat-api 2>$null
    docker -H tcp://$ServerIP`:2376 rm wechat-api 2>$null
    
    Write-Host "拉取新镜像..." -ForegroundColor Yellow
    docker -H tcp://$ServerIP`:2376 pull $ServerIP`:5000/wechat-api-net8:alpine-musl-json-fixed
    
    Write-Host "启动新容器..." -ForegroundColor Yellow
    $containerId = docker -H tcp://$ServerIP`:2376 run -d `
      --name wechat-api `
      --restart unless-stopped `
      -p 8090:8080 `
      -p 8091:8081 `
      -p 8092:8082 `
      -v /etc/localtime:/etc/localtime:ro `
      --memory=512m `
      --cpus="1" `
      $ServerIP`:5000/wechat-api-net8:alpine-musl-json-fixed
    
    Write-Host "容器ID: $containerId" -ForegroundColor Green
    
    Write-Host "等待容器启动..." -ForegroundColor Yellow
    Start-Sleep 10
    
    Write-Host "检查容器状态:" -ForegroundColor Yellow
    docker -H tcp://$ServerIP`:2376 ps | Select-String "wechat-api"
    
    Write-Host "容器启动日志:" -ForegroundColor Yellow
    docker -H tcp://$ServerIP`:2376 logs wechat-api --tail 20
    
    Write-Host "`n部署完成! 访问地址:" -ForegroundColor Green
    Write-Host "HTTP:  http://$ServerIP`:8090/swagger" -ForegroundColor Cyan
    Write-Host "HTTPS: https://$ServerIP`:8091/swagger" -ForegroundColor Cyan
    Write-Host "HTTPS2: https://$ServerIP`:8092/swagger" -ForegroundColor Cyan
    
} catch {
    Write-Host "部署过程中出现错误: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "如果是远程Docker连接问题，请手动在服务器上执行部署命令" -ForegroundColor Yellow
}