# JSON反序列化问题诊断脚本
Write-Host "=== JSON反序列化问题精确诊断 ===" -ForegroundColor Green

$baseUrl = "http://192.168.137.101:8080"

Write-Host "`n1. 测试诊断端点 - 标准绑定:" -ForegroundColor Cyan
$testJson = @{
    "domain" = "qsgl.net"
    "isWildcard" = $true
} | ConvertTo-Json

Write-Host "发送JSON: $testJson" -ForegroundColor Yellow

try {
    $result1 = Invoke-RestMethod -Uri "$baseUrl/api/Certificate/test" -Method POST -Body $testJson -ContentType "application/json" -TimeoutSec 10
    Write-Host "✓ 标准绑定测试完成" -ForegroundColor Green
    Write-Host "结果: $($result1 | ConvertTo-Json -Depth 3)" -ForegroundColor White
} catch {
    Write-Host "✗ 标准绑定测试失败: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n2. 测试原始JSON处理:" -ForegroundColor Cyan
try {
    $result2 = Invoke-RestMethod -Uri "$baseUrl/api/Certificate/test-raw" -Method POST -Body $testJson -ContentType "application/json" -TimeoutSec 10
    Write-Host "✓ 原始JSON处理完成" -ForegroundColor Green
    Write-Host "结果: $($result2 | ConvertTo-Json -Depth 3)" -ForegroundColor White
} catch {
    Write-Host "✗ 原始JSON处理失败: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n3. 测试不同的JSON格式:" -ForegroundColor Cyan

# 测试3.1: 明确的字符串格式
$testJson2 = '{"domain":"qsgl.net","isWildcard":true}'
Write-Host "发送格式2: $testJson2" -ForegroundColor Yellow

try {
    $result3 = Invoke-RestMethod -Uri "$baseUrl/api/Certificate/test" -Method POST -Body $testJson2 -ContentType "application/json" -TimeoutSec 10
    Write-Host "✓ 格式2测试完成" -ForegroundColor Green
    Write-Host "结果: $($result3 | ConvertTo-Json -Depth 3)" -ForegroundColor White
} catch {
    Write-Host "✗ 格式2测试失败: $($_.Exception.Message)" -ForegroundColor Red
}

# 测试3.2: 使用双引号转义
$testJson3 = @"
{
    "domain": "qsgl.net",
    "isWildcard": true
}
"@
Write-Host "发送格式3: $testJson3" -ForegroundColor Yellow

try {
    $result4 = Invoke-RestMethod -Uri "$baseUrl/api/Certificate/test" -Method POST -Body $testJson3 -ContentType "application/json" -TimeoutSec 10
    Write-Host "✓ 格式3测试完成" -ForegroundColor Green
    Write-Host "结果: $($result4 | ConvertTo-Json -Depth 3)" -ForegroundColor White
} catch {
    Write-Host "✗ 格式3测试失败: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== 诊断完成 ===" -ForegroundColor Green
Write-Host "请查看上述测试结果，确定哪种格式能正确传递域名值" -ForegroundColor Yellow