# SSH自动登录脚本
param(
    [string]$Command = "echo '=== 容器进程列表 ==='; docker exec wechat-api ps aux; echo '=== 检查应用启动错误 ==='; docker logs wechat-api --tail 100 | grep -i 'error\|exception\|fail'; echo '=== 检查端口监听情况 ==='; docker exec wechat-api netstat -tlnp 2>/dev/null || echo 'netstat not available'"
)

$serverIP = "43.138.35.183"
$username = "root"
$password = "galaxy_s24"

try {
    # 方法1: 使用plink (PuTTY工具)
    if (Get-Command plink -ErrorAction SilentlyContinue) {
        Write-Host "使用plink连接..." -ForegroundColor Green
        echo $password | plink -ssh -l $username -pw $password $serverIP $Command
    }
    # 方法2: 使用expect (如果安装了)
    elseif (Get-Command expect -ErrorAction SilentlyContinue) {
        Write-Host "使用expect连接..." -ForegroundColor Green
        $expectScript = @"
spawn ssh $username@$serverIP "$Command"
expect "password:"
send "$password\r"
expect eof
"@
        $expectScript | expect
    }
    # 方法3: 使用PowerShell直接方式
    else {
        Write-Host "使用标准SSH连接..." -ForegroundColor Green
        $processInfo = New-Object System.Diagnostics.ProcessStartInfo
        $processInfo.FileName = "ssh"
        $processInfo.Arguments = "-o StrictHostKeyChecking=no $username@$serverIP `"$Command`""
        $processInfo.UseShellExecute = $false
        $processInfo.RedirectStandardInput = $true
        $processInfo.RedirectStandardOutput = $true
        $processInfo.RedirectStandardError = $true
        
        $process = New-Object System.Diagnostics.Process
        $process.StartInfo = $processInfo
        $process.Start() | Out-Null
        
        # 发送密码
        $process.StandardInput.WriteLine($password)
        $process.StandardInput.Close()
        
        $output = $process.StandardOutput.ReadToEnd()
        $error = $process.StandardError.ReadToEnd()
        $process.WaitForExit()
        
        if ($output) { Write-Host $output }
        if ($error) { Write-Host $error -ForegroundColor Red }
    }
}
catch {
    Write-Host "SSH连接失败: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "回退到手动输入密码方式..." -ForegroundColor Yellow
    ssh -o StrictHostKeyChecking=no $username@$serverIP $Command
}