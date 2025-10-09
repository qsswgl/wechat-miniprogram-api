# 测试不同HTTP协议的API端点
Write-Host "=== 测试微信小程序二维码生成API - 多协议支持 ===" -ForegroundColor Green
Write-Host ""

# 检查服务是否运行
Write-Host "检查API服务状态..." -ForegroundColor Yellow

# 测试HTTP/1.1端点 (8080)
Write-Host "`n[HTTP/1.1] 测试端口 8080:" -ForegroundColor Cyan
try {
    $response1 = Invoke-RestMethod -Uri "http://127.0.0.1:8080/WeChat/info" -Method GET -TimeoutSec 5
    Write-Host "✓ HTTP/1.1 连接成功" -ForegroundColor Green
    Write-Host "响应: $($response1 | ConvertTo-Json -Depth 3)" -ForegroundColor White
} catch {
    Write-Host "✗ HTTP/1.1 连接失败: $($_.Exception.Message)" -ForegroundColor Red
}

# 测试HTTP/2端点 (8081) - 需要HTTPS
Write-Host "`n[HTTP/2] 测试端口 8081 (HTTPS):" -ForegroundColor Cyan
try {
    # 忽略SSL证书验证（开发环境）
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
    $response2 = Invoke-RestMethod -Uri "https://127.0.0.1:8081/WeChat/info" -Method GET -TimeoutSec 5 -SkipCertificateCheck
    Write-Host "✓ HTTP/2 连接成功" -ForegroundColor Green
    Write-Host "响应: $($response2 | ConvertTo-Json -Depth 3)" -ForegroundColor White
} catch {
    Write-Host "✗ HTTP/2 连接失败: $($_.Exception.Message)" -ForegroundColor Red
}

# 测试HTTP/3端点 (8082) - 需要HTTPS
Write-Host "`n[HTTP/3] 测试端口 8082 (HTTPS):" -ForegroundColor Cyan
try {
    $response3 = Invoke-RestMethod -Uri "https://127.0.0.1:8082/WeChat/info" -Method GET -TimeoutSec 5 -SkipCertificateCheck
    Write-Host "✓ HTTP/3 连接成功" -ForegroundColor Green  
    Write-Host "响应: $($response3 | ConvertTo-Json -Depth 3)" -ForegroundColor White
} catch {
    Write-Host "✗ HTTP/3 连接失败: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== 测试微信小程序二维码生成 ===" -ForegroundColor Green

# 测试二维码生成API
$qrData = @{
    scene = "test123"
    width = 280
    page = "pages/index/index"
} | ConvertTo-Json

Write-Host "`n测试二维码生成接口:" -ForegroundColor Yellow
try {
    $qrResponse = Invoke-RestMethod -Uri "http://127.0.0.1:8080/WeChat/generateQrCode" -Method POST -Body $qrData -ContentType "application/json" -TimeoutSec 10
    Write-Host "✓ 二维码生成成功" -ForegroundColor Green
    Write-Host "响应: $($qrResponse | ConvertTo-Json -Depth 3)" -ForegroundColor White
} catch {
    Write-Host "✗ 二维码生成失败: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== 测试完成 ===" -ForegroundColor Green
Write-Host "API服务正在以下端点运行:"
Write-Host "- HTTP/1.1: http://127.0.0.1:8080" -ForegroundColor White
Write-Host "- HTTP/2:   https://127.0.0.1:8081" -ForegroundColor White  
Write-Host "- HTTP/3:   https://127.0.0.1:8082" -ForegroundColor White
Write-Host "- Swagger:  http://127.0.0.1:8080/swagger" -ForegroundColor White