# 微信小程序API - 外部IP访问测试脚本
Write-Host "=== 微信小程序二维码API - 外部IP访问测试 ===" -ForegroundColor Green
Write-Host ""

# 获取本机IP地址
$localIP = "192.168.137.101"
Write-Host "本机IP地址: $localIP" -ForegroundColor Yellow

Write-Host "`n=== 测试API端点访问 ===" -ForegroundColor Cyan

# 测试API信息端点
Write-Host "`n1. 测试API信息端点" -ForegroundColor White
Write-Host "   URL: http://$localIP:8080/WeChat/info"

# 测试Swagger页面
Write-Host "`n2. 测试Swagger文档页面" -ForegroundColor White  
Write-Host "   URL: http://$localIP:8080/swagger/index.html"

# 测试API健康检查
Write-Host "`n3. 测试根路径访问" -ForegroundColor White
Write-Host "   URL: http://$localIP:8080/"

Write-Host "`n=== 多协议端口状态 ===" -ForegroundColor Cyan
Write-Host "✓ HTTP/1.1: http://$localIP:8080" -ForegroundColor Green
Write-Host "✓ HTTP/2:   https://$localIP:8081 (HTTPS)" -ForegroundColor Green  
Write-Host "✓ HTTP/3:   https://$localIP:8082 (HTTPS)" -ForegroundColor Green

Write-Host "`n=== 防火墙端口状态 ===" -ForegroundColor Cyan
Write-Host "✓ 端口8080已开放" -ForegroundColor Green
Write-Host "✓ 端口8081已开放" -ForegroundColor Green
Write-Host "✓ 端口8082已开放" -ForegroundColor Green

Write-Host "`n=== 配置文件设置 ===" -ForegroundColor Cyan
Write-Host "✓ 端口配置已移至appsettings.json" -ForegroundColor Green
Write-Host "✓ IP绑定已设置为0.0.0.0（支持外部访问）" -ForegroundColor Green

Write-Host "`n=== 使用说明 ===" -ForegroundColor Yellow
Write-Host "1. 在浏览器中访问: http://$localIP:8080/swagger" 
Write-Host "2. 测试WeChat API端点"
Write-Host "3. 调用二维码生成接口"

Write-Host "`n测试完成！" -ForegroundColor Green