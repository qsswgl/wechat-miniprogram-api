# 生成开发用的SSL证书脚本
# 运行此脚本前，请确保已安装OpenSSL

# 生成私钥
openssl genrsa -out testCert.key 2048

# 生成证书请求
openssl req -new -key testCert.key -out testCert.csr -subj "/C=CN/ST=Beijing/L=Beijing/O=Test/OU=Test/CN=localhost"

# 生成自签名证书
openssl x509 -req -days 365 -in testCert.csr -signkey testCert.key -out testCert.crt

# 生成PFX文件
openssl pkcs12 -export -out testCert.pfx -inkey testCert.key -in testCert.crt -password pass:testPassword

Write-Host "SSL证书已生成完成！"
Write-Host "文件位置："
Write-Host "  - testCert.pfx (用于.NET应用)"
Write-Host "  - testCert.key (私钥)"
Write-Host "  - testCert.crt (公钥证书)"
Write-Host ""
Write-Host "注意：这是开发用的自签名证书，生产环境请使用正式证书。"