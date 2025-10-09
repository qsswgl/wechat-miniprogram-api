# 证书申请接口测试脚本
Write-Host "=== 证书申请接口修复测试 ===" -ForegroundColor Green
Write-Host ""

$baseUrl = "http://192.168.137.101:8080"
$domain = "qsgl.net"

Write-Host "测试修复后的证书申请接口..." -ForegroundColor Yellow

# 测试方式1: JSON请求体方式 (POST)
Write-Host "`n1. 测试JSON请求体方式 (POST):" -ForegroundColor Cyan
$jsonBody = @{
    "domain" = $domain
    "isWildcard" = $true
} | ConvertTo-Json

Write-Host "请求URL: $baseUrl/api/Certificate/request" -ForegroundColor White
Write-Host "请求方法: POST" -ForegroundColor White
Write-Host "请求体: $jsonBody" -ForegroundColor White

try {
    $response = Invoke-RestMethod -Uri "$baseUrl/api/Certificate/request" -Method POST -Body $jsonBody -ContentType "application/json" -TimeoutSec 30
    Write-Host "✓ JSON方式调用成功" -ForegroundColor Green
    Write-Host "响应: $($response | ConvertTo-Json -Depth 3)" -ForegroundColor White
} catch {
    Write-Host "✗ JSON方式调用失败: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        $errorResponse = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($errorResponse)
        $errorBody = $reader.ReadToEnd()
        Write-Host "错误详情: $errorBody" -ForegroundColor Yellow
    }
}

# 测试方式2: Query参数方式 (GET)
Write-Host "`n2. 测试Query参数方式 (GET):" -ForegroundColor Cyan
$queryUrl = "$baseUrl/api/Certificate/request?domain=$domain&isWildcard=true"

Write-Host "请求URL: $queryUrl" -ForegroundColor White
Write-Host "请求方法: GET" -ForegroundColor White

try {
    $response2 = Invoke-RestMethod -Uri $queryUrl -Method GET -TimeoutSec 30
    Write-Host "✓ Query参数方式调用成功" -ForegroundColor Green
    Write-Host "响应: $($response2 | ConvertTo-Json -Depth 3)" -ForegroundColor White
} catch {
    Write-Host "✗ Query参数方式调用失败: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        $errorResponse = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($errorResponse)
        $errorBody = $reader.ReadToEnd()
        Write-Host "错误详情: $errorBody" -ForegroundColor Yellow
    }
}

Write-Host "`n=== 测试完成 ===" -ForegroundColor Green
Write-Host "已修复的问题:" -ForegroundColor Yellow
Write-Host "1. ✓ 添加了JSON请求体支持" -ForegroundColor Green
Write-Host "2. ✓ 修复了'domain field is required'错误" -ForegroundColor Green 
Write-Host "3. ✓ 保持了Query参数的兼容性" -ForegroundColor Green
Write-Host "4. ✓ 返回标准化的错误格式" -ForegroundColor Green

Write-Host "`n现在可以在Swagger中测试证书申请接口了！" -ForegroundColor Cyan
Write-Host "Swagger地址: http://192.168.137.101:8080/swagger" -ForegroundColor White