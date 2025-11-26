Param(
  [string]$ContainerName = "wechat-api"
)

# 邮件告警配置（从环境变量读取）
$AlertEmailEnabled = [System.Environment]::GetEnvironmentVariable('ALERT_EMAIL_ENABLED') -eq 'true'
$SmtpServer = [System.Environment]::GetEnvironmentVariable('SMTP_SERVER', 'smtp.139.com')
$SmtpPort = [System.Environment]::GetEnvironmentVariable('SMTP_PORT', '25')
$SmtpUser = [System.Environment]::GetEnvironmentVariable('SMTP_USER')
$SmtpPass = [System.Environment]::GetEnvironmentVariable('SMTP_PASS')
$AlertEmailTo = [System.Environment]::GetEnvironmentVariable('ALERT_EMAIL_TO')

$timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'

Function Log($msg) {
  $line = "[$timestamp] $msg"
  Write-Host $line
}

Function Send-AlertEmail($subject, $body) {
  if (-not $AlertEmailEnabled -or -not $SmtpUser -or -not $SmtpPass -or -not $AlertEmailTo) {
    return
  }
  
  try {
    $securePass = ConvertTo-SecureString $SmtpPass -AsPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential($SmtpUser, $securePass)
    
    Send-MailMessage -SmtpServer $SmtpServer `
                     -Port $SmtpPort `
                     -From $SmtpUser `
                     -To $AlertEmailTo `
                     -Subject $subject `
                     -Body $body `
                     -Credential $credential `
                     -Encoding UTF8 `
                     -ErrorAction SilentlyContinue
  } catch {
    Log "邮件发送失败: $($_.Exception.Message)"
  }
}

Function Notify($message) {
  Log $message
  $emailBody = @"
$message

时间: $timestamp
容器: $ContainerName
主机: $env:COMPUTERNAME

请及时检查服务状态。
"@
  Send-AlertEmail "[WeChat API 告警] $ContainerName" $emailBody
}

try {
  $container = docker ps --format '{{.Names}}' | Select-String -Pattern "^$ContainerName$"
  if (-not $container) {
    Log "容器未运行，尝试启动..."
    docker start $ContainerName | Out-Null
    Start-Sleep -Seconds 5
  }

  $health = docker inspect -f '{{ if .State.Health }}{{ .State.Health.Status }}{{ else }}unknown{{ end }}' $ContainerName 2>$null
  if ($health -eq 'healthy') {
    Log "容器健康(healthy)"
    exit 0
  }

  # 二次校验
  docker exec $ContainerName sh -c 'curl -kfsS https://localhost:8082/api/health >/dev/null' 2>$null
  if ($LASTEXITCODE -eq 0) {
    Log "端点健康但 Docker 健康状态=$health，可能是健康检查延迟"
    exit 0
  }

  Log "检测到容器不健康(Health=$health)，执行重启..."
  docker restart $ContainerName | Out-Null
  Start-Sleep -Seconds 8
  docker exec $ContainerName sh -c 'curl -kfsS https://localhost:8082/api/health >/dev/null' 2>$null
  if ($LASTEXITCODE -eq 0) {
    Notify "wechat-api异常已自动重启恢复"
    exit 0
  } else {
    Notify "wechat-api重启后仍异常，请排查"
    exit 1
  }
} catch {
  Log "监控脚本异常：$($_.Exception.Message)"
  exit 1
}
