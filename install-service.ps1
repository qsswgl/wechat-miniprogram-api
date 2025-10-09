# 安装为 Windows 服务
# 需要管理员 PowerShell
param(
    [string]$ServiceName = "QSGLAPI",
    [string]$DisplayName = "QSGL API Service",
    [string]$Description = "QSGL API with HTTP/3 and SSL",
    [string]$PublishPath = "$PSScriptRoot\publish\win-x64"
)

$ErrorActionPreference = 'Stop'

$exe = Join-Path $PublishPath "WeChatMiniProgramAPI.exe"
if (!(Test-Path $exe)) {
    throw "未找到可执行文件: $exe，请先运行 publish.ps1"
}

# 尝试停止并删除已存在的服务
$existing = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
if ($existing) {
    if ($existing.Status -ne 'Stopped') { Stop-Service -Name $ServiceName -Force -ErrorAction SilentlyContinue }
    sc.exe delete $ServiceName | Out-Null
    Start-Sleep -Seconds 2
}

# 安装服务（以本地系统身份运行）
New-Service -Name $ServiceName -BinaryPathName "\"$exe\"" -DisplayName $DisplayName -Description $Description -StartupType Automatic

# 授权服务账号读取目录（如证书）
$acl = Get-Acl $PublishPath
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule("NT AUTHORITY\\LocalService","ReadAndExecute, Synchronize","ContainerInherit,ObjectInherit","None","Allow")
$acl.AddAccessRule($rule)
Set-Acl -Path $PublishPath -AclObject $acl

Start-Service -Name $ServiceName
Write-Host "服务已安装并启动: $ServiceName"
