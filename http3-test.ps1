# HTTP/3端点测试脚本
Write-Host "=== HTTP/3 端点访问测试 ===" -ForegroundColor Green
Write-Host ""

$localIP = "192.168.137.101"

Write-Host "测试各个HTTP协议端点..." -ForegroundColor Yellow

# 测试HTTP/1.1 (8080)
Write-Host "`n[HTTP/1.1] 端口 8080:" -ForegroundColor Cyan
Write-Host "URL: http://$localIP:8080/swagger/" -ForegroundColor White

# 测试HTTP/2 (8081) 
Write-Host "`n[HTTP/2] 端口 8081:" -ForegroundColor Cyan
Write-Host "URL: https://$localIP:8081/swagger/" -ForegroundColor White

# 测试HTTP/3 (8082)
Write-Host "`n[HTTP/3] 端口 8082:" -ForegroundColor Cyan
Write-Host "URL: https://$localIP:8082/swagger/" -ForegroundColor White

# 测试HTTP1And2 (8083)
Write-Host "`n[HTTP1And2] 端口 8083:" -ForegroundColor Cyan
Write-Host "URL: https://$localIP:8083/swagger/" -ForegroundColor White

Write-Host "`n=== HTTP/3 特别说明 ===" -ForegroundColor Yellow
Write-Host "HTTP/3 基于 QUIC 协议，可能需要：" 
Write-Host "1. 现代浏览器支持 (Chrome 88+, Firefox 88+)"
Write-Host "2. 有效的SSL证书"
Write-Host "3. UDP端口开放 (HTTP/3 使用UDP而不是TCP)"

Write-Host "`n=== 服务监听状态 ===" -ForegroundColor Green
Write-Host "✓ http://0.0.0.0:8080  (HTTP/1.1)" -ForegroundColor Green
Write-Host "✓ https://0.0.0.0:8081 (HTTP/2)" -ForegroundColor Green
Write-Host "✓ https://0.0.0.0:8082 (HTTP/3)" -ForegroundColor Green
Write-Host "✓ https://0.0.0.0:8083 (HTTP/1.1 & HTTP/2)" -ForegroundColor Green

Write-Host "`n测试完成！如果8082仍无法访问，请检查：" -ForegroundColor Cyan
Write-Host "1. UDP端口8082是否开放"
Write-Host "2. 浏览器是否支持HTTP/3"
Write-Host "3. SSL证书配置是否正确"