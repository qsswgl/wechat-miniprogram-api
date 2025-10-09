# 卸载 Windows 服务
param(
    [string]$ServiceName = "QSGLAPI"
)

$ErrorActionPreference = 'Stop'

$svc = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
if ($svc) {
    if ($svc.Status -ne 'Stopped') { Stop-Service -Name $ServiceName -Force -ErrorAction SilentlyContinue }
    sc.exe delete $ServiceName | Out-Null
    Start-Sleep -Seconds 2
    Write-Host "服务已删除: $ServiceName"
} else {
    Write-Host "未找到服务: $ServiceName"
}
