@echo off
chcp 65001 >nul
echo ====================================================
echo    WeChat API 快速部署 - tx.qsgl.net
echo ====================================================
echo.

set SERVER=root@43.138.35.183
set SSH_KEY=tx.qsgl.net_id_ed25519

echo [1/4] 上传配置文件...
scp -i %SSH_KEY% docker-compose.production.yml %SERVER%:/root/wechat-api/
scp -i %SSH_KEY% .env.example %SERVER%:/root/wechat-api/.env
echo [OK] 配置文件已上传
echo.

echo [2/4] 上传监控脚本...
ssh -i %SSH_KEY% %SERVER% "mkdir -p /opt/scripts"
scp -i %SSH_KEY% scripts\monitor-wechat-api.sh %SERVER%:/opt/scripts/
ssh -i %SSH_KEY% %SERVER% "chmod +x /opt/scripts/monitor-wechat-api.sh"
echo [OK] 监控脚本已上传
echo.

echo [3/4] 拉取并启动容器...
ssh -i %SSH_KEY% %SERVER% "cd /root/wechat-api && docker pull 43.138.35.183:5000/wechat-api-net8:latest && docker-compose -f docker-compose.production.yml down && docker-compose -f docker-compose.production.yml up -d"
echo [OK] 容器已启动
echo.

echo [4/4] 验证部署...
timeout /t 5 /nobreak >nul
ssh -i %SSH_KEY% %SERVER% "docker ps --filter name=wechat-api"
echo.

echo ====================================================
echo    部署完成!
echo ====================================================
echo.
echo 访问地址:
echo   - API健康检查: https://43.138.35.183:8092/api/health
echo   - Swagger文档:  https://43.138.35.183:8092/swagger
echo.
echo 管理命令:
echo   - 查看日志: ssh -i %SSH_KEY% %SERVER% "docker logs -f wechat-api"
echo   - 重启容器: ssh -i %SSH_KEY% %SERVER% "cd /root/wechat-api && docker-compose -f docker-compose.production.yml restart"
echo.
pause
