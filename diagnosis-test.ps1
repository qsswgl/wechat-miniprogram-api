# 测试JSON反序列化和证书申请
Write-Host "=== 测试JSON反序列化问题诊断 ===" -ForegroundColor Green

$baseUrl = "http://192.168.137.101:8080"

# 测试1: 诊断JSON反序列化
Write-Host "`n1. 测试JSON反序列化:" -ForegroundColor Cyan
$testJson = @{
    "domain" = "qsgl.net"
    "isWildcard" = $true
} | ConvertTo-Json

Write-Host "发送JSON: $testJson" -ForegroundColor Yellow

try {
    $testResult = Invoke-RestMethod -Uri "$baseUrl/api/Certificate/test" -Method POST -Body $testJson -ContentType "application/json" -TimeoutSec 10
    Write-Host "✓ 反序列化测试成功" -ForegroundColor Green
    Write-Host "结果: $($testResult | ConvertTo-Json -Depth 3)" -ForegroundColor White
} catch {
    Write-Host "✗ 反序列化测试失败: $($_.Exception.Message)" -ForegroundColor Red
}

# 测试2: 用正确的域名测试证书申请
Write-Host "`n2. 测试证书申请 (qsgl.net):" -ForegroundColor Cyan
$certJson = @{
    "domain" = "qsgl.net"
    "isWildcard" = $true
} | ConvertTo-Json

Write-Host "发送域名: qsgl.net" -ForegroundColor Yellow

try {
    $certResult = Invoke-RestMethod -Uri "$baseUrl/api/Certificate/request" -Method POST -Body $certJson -ContentType "application/json" -TimeoutSec 60
    Write-Host "✓ 证书申请成功" -ForegroundColor Green
    Write-Host "结果: $($certResult | ConvertTo-Json -Depth 3)" -ForegroundColor White
} catch {
    Write-Host "✗ 证书申请失败: $($_.Exception.Message)" -ForegroundColor Red
    
    # 获取详细错误信息
    try {
        $errorStream = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($errorStream)
        $errorBody = $reader.ReadToEnd()
        Write-Host "详细错误: $errorBody" -ForegroundColor Yellow
    } catch {
        Write-Host "无法获取详细错误信息" -ForegroundColor Gray
    }
}

Write-Host "`n=== 测试完成 ===" -ForegroundColor Green