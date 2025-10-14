# 停止并删除现有容器
Write-Host "停止现有容器..." -ForegroundColor Yellow
docker stop wechat-api 2>$null
docker rm wechat-api 2>$null

# 拉取最新镜像
Write-Host "拉取最新镜像..." -ForegroundColor Yellow
docker pull 43.138.35.183:5000/wechat-api-net8:alpine-musl-ssl-swagger-fixed

# 启动新容器
Write-Host "启动新容器..." -ForegroundColor Yellow
docker run -d `
  --name wechat-api `
  --restart unless-stopped `
  -p 8090:8090 `
  -p 8091:8091 `
  -p 8092:8092 `
  -e DOTNET_RUNNING_IN_CONTAINER=true `
  -e ASPNETCORE_ENVIRONMENT=Production `
  43.138.35.183:5000/wechat-api-net8:alpine-musl-ssl-swagger-fixed

Write-Host ""
Write-Host "Docker容器已启动！" -ForegroundColor Green
Write-Host "访问地址：" -ForegroundColor Cyan
Write-Host "HTTP:  http://43.138.35.183:8090/swagger" -ForegroundColor White
Write-Host "HTTPS: https://43.138.35.183:8091/swagger" -ForegroundColor White
Write-Host ""
Write-Host "健康检查：" -ForegroundColor Cyan
Write-Host "http://43.138.35.183:8090/api/health" -ForegroundColor White
Write-Host "http://43.138.35.183:8090/api/health/info" -ForegroundColor White
Write-Host ""
Write-Host "容器状态检查：" -ForegroundColor Cyan
docker ps --filter "name=wechat-api"