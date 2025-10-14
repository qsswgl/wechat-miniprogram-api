# 修复SSH密钥权限
$keyFile = "K:\QSGLAPI\WeChatMiniProgramAPI\ssh_private_key"

try {
    # 获取当前用户
    $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    Write-Host "当前用户: $currentUser"
    
    # 获取文件ACL
    $acl = Get-Acl $keyFile
    
    # 禁用继承并清除所有权限
    $acl.SetAccessRuleProtection($true, $false)
    
    # 只给当前用户读取权限
    $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($currentUser, "Read", "Allow")
    $acl.SetAccessRule($accessRule)
    
    # 应用新的ACL
    Set-Acl -Path $keyFile -AclObject $acl
    
    Write-Host "SSH密钥权限已修复！" -ForegroundColor Green
    
    # 验证权限
    $newAcl = Get-Acl $keyFile
    Write-Host "新权限："
    $newAcl.Access | Format-Table IdentityReference, FileSystemRights, AccessControlType
    
} catch {
    Write-Host "修复权限时出错: $($_.Exception.Message)" -ForegroundColor Red
}