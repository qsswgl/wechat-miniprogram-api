#!/bin/bash

echo "==============================================="
echo "    QSGL WeChat API - 修复后重新部署"
echo "==============================================="
echo

echo "[1/4] 清理重复文件和构建缓存..."
# 删除导致冲突的目录和文件
rm -rf docker-deploy/ || true
rm -f qsgl-api-docker.zip || true

# 清理Docker缓存
docker system prune -f

echo "[2/4] 停止现有容器..."
docker-compose down

echo "[3/4] 重新构建镜像（无缓存）..."
docker-compose build --no-cache --pull

if [ $? -ne 0 ]; then
    echo "❌ 构建失败！检查错误信息..."
    exit 1
fi

echo "[4/4] 启动服务..."
docker-compose up -d

echo
echo "🎉 部署完成！"
echo
echo "检查服务状态..."
sleep 3
docker-compose ps

echo
echo "📋 服务访问地址："
echo "  HTTP:  http://123.57.93.200:8080/swagger"
echo "  HTTPS: https://123.57.93.200:8081/swagger"
echo "  HTTP/3: https://123.57.93.200:8082/swagger"
echo
echo "📋 管理命令："
echo "  查看日志: docker-compose logs -f"
echo "  重启服务: docker-compose restart"
echo "  停止服务: docker-compose down"
echo