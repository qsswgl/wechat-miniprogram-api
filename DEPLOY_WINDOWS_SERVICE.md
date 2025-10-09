# 部署为 Windows 服务

本应用支持作为 Windows 服务运行，且所有监听端口与证书路径都可在 `appsettings.json` 的 `Kestrel:Endpoints` 中修改。

## 步骤

1) 生成发布包（管理员 PowerShell）：

   ./publish.ps1

   输出目录：`publish/win-x64`

2) 安装服务：

   # 可选参数：-ServiceName, -DisplayName, -Description, -PublishPath
   ./install-service.ps1

3) 验证服务运行：

   - 打开服务管理器，找到 "QSGLAPI"
   - 或在浏览器访问：
     - http://<服务器IP>:8080/swagger
     - https://<服务器IP或域名>:8081/swagger
     - https://<服务器IP或域名>:8082/swagger (HTTP/3)
     - https://<服务器IP或域名>:8083/swagger

4) 修改端口或证书

   - 编辑 `publish/win-x64/appsettings.json` 中的 `Kestrel:Endpoints`，调整 Url、Protocols、Certificate.Path/Password
   - 修改后，重启服务：
     - Stop-Service QSGLAPI; Start-Service QSGLAPI

5) 卸载服务（如需）：

   ./uninstall-service.ps1

## 证书

- 已生成的 PFX 会被复制到 `publish/win-x64/certificates` 目录。
- 若更换证书，更新 `appsettings.json` 中对应路径与密码即可。

## 注意

- 首次在服务器上运行 HTTP/3 需要 OS 支持（Windows Server 2022/Win11），并开放 UDP 端口（如 8082）。
- 防火墙需放行对应端口（TCP: 8080/8081/8083，UDP: 8082）。
- 服务默认以 LocalService 运行，确保其对发布目录具有读取权限（脚本已授予）。若证书在其他目录，请相应授予权限。
