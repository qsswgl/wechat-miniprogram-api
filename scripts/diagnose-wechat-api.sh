#!/bin/bash
# 自动诊断脚本：收集 wechat-api 容器状态、健康检查、日志、网络与磁盘信息
# 用法：bash scripts/diagnose-wechat-api.sh [container_name]

set -euo pipefail
CONTAINER_NAME=${1:-wechat-api}

echo "=== [1/8] 容器基本信息 ==="
docker ps -a --filter "name=${CONTAINER_NAME}" --format 'table {{.Names}}\t{{.Status}}\t{{.Image}}\t{{.Ports}}' || true

echo
echo "=== [2/8] 重启策略与健康检查 ==="
docker inspect -f 'RestartPolicy: {{ .HostConfig.RestartPolicy.Name }} (max: {{ .HostConfig.RestartPolicy.MaximumRetryCount }})' ${CONTAINER_NAME} 2>/dev/null || echo "容器不存在"
docker inspect -f 'Health: {{ if .State.Health }}{{ .State.Health.Status }}{{ else }}N/A{{ end }}' ${CONTAINER_NAME} 2>/dev/null || true

echo
echo "=== [3/8] 关键端口监听 (宿主) ==="
ss -tulpen | grep -E ':(8090|8091|8092)\s' || echo "未发现目标端口监听"

echo
echo "=== [4/8] 容器内健康探测 ==="
if docker exec ${CONTAINER_NAME} sh -c 'which curl >/dev/null 2>&1'; then
  docker exec ${CONTAINER_NAME} sh -c 'curl -kfsS https://localhost:8082/api/health || true'
else
  echo "容器内未安装curl，跳过"
fi

echo
echo "=== [5/8] 最近100行容器日志 ==="
docker logs --tail 100 ${CONTAINER_NAME} 2>&1 || true

echo
echo "=== [6/8] 卷与挂载 ==="
docker inspect -f '{{ json .Mounts }}' ${CONTAINER_NAME} 2>/dev/null | jq '.' || echo "请安装jq以获得更好输出，原始：" && docker inspect ${CONTAINER_NAME} | grep -A3 Mounts || true

echo
echo "=== [7/8] 宿主磁盘与权限建议 ==="
df -h | sed -n "1p;/\\/data/p;/\\/var/p;/\\/home/p"
echo "建议上传目录挂载到 /data/wechat-uploadall，并设置 chown 1001:1001; chmod 755"

echo
echo "=== [8/8] 容器事件 (最近50条) ==="
docker events --since 30m --until 0s --format 'table {{.Time}}\t{{.Type}}\t{{.Action}}\t{{.Actor.Attributes.name}}' 2>/dev/null | head -n 50 || echo "docker events 不可用或无数据"

echo
echo "完成。若需进一步导出，请运行：docker inspect ${CONTAINER_NAME} > diagnose-${CONTAINER_NAME}.json"
