Write-Host "=== 测试微信小程序二维码生成API - 多协议支持 ===" -ForegroundColor Green

# 测试HTTP/1.1端点
Write-Host "`n[HTTP/1.1] 测试端口 8080:" -ForegroundColor Cyan
try {
    $response = Invoke-RestMethod -Uri "http://127.0.0.1:8080/WeChat/info" -Method GET -TimeoutSec 5
    Write-Host "成功连接到HTTP/1.1端口8080" -ForegroundColor Green
    Write-Host "响应数据: $($response | ConvertTo-Json)" -ForegroundColor White
} catch {
    Write-Host "连接失败: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n多协议API服务运行状态:"
Write-Host "- HTTP/1.1: http://127.0.0.1:8080" -ForegroundColor White
Write-Host "- HTTP/2:   https://127.0.0.1:8081" -ForegroundColor White  
Write-Host "- HTTP/3:   https://127.0.0.1:8082" -ForegroundColor White