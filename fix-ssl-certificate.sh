#!/bin/bash
echo "===== 解决SSL证书问题 - 上传证书方案 ====="

# 停止当前崩溃的容器
echo "[1] 停止崩溃的容器..."
docker stop wechat-api
docker rm wechat-api

# 检查证书目录
echo "[2] 检查证书目录..."
ls -la /root/certificates/

echo ""
echo "需要确保 /root/certificates/qsgl.net.pfx 文件存在"
echo "如果不存在，请执行以下操作之一："
echo ""
echo "选项A: 从Windows上传证书文件"
echo "scp C:\\QSGLAPI\\WeChatMiniProgramAPI\\certificates\\qsgl.net.pfx root@43.138.35.183:/root/certificates/"
echo ""
echo "选项B: 手动复制证书内容"
echo "cat > /root/certificates/qsgl.net.pfx << 'EOF'"
echo "# 在这里粘贴证书文件内容"
echo "EOF"
echo ""
echo "选项C: 下载证书文件"
echo "wget -O /root/certificates/qsgl.net.pfx 'your-certificate-download-url'"
echo ""

# 检查证书文件是否存在
if [ -f "/root/certificates/qsgl.net.pfx" ]; then
    echo "✅ 证书文件存在，继续部署..."
    
    # 重新创建容器
    docker run -d \
      --name wechat-api \
      --restart unless-stopped \
      -p 8080:8080 \
      -p 8081:8081 \
      -p 8082:8082 \
      -v /root/certificates:/app/certificates:ro \
      -e ASPNETCORE_ENVIRONMENT=Production \
      43.138.35.183:5000/wechat-api-net8:alpine-musl
    
    echo "等待启动..."
    sleep 10
    
    echo "检查状态:"
    docker ps | grep wechat-api
    docker logs wechat-api | tail -5
    
else
    echo "❌ 证书文件不存在!"
    echo "请先上传证书文件到 /root/certificates/qsgl.net.pfx"
    echo "然后重新运行此脚本"
fi