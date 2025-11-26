#!/bin/bash
# 一键为现有容器设置自动重启策略
# 用法：bash scripts/enforce-restart-policy.sh [container_name]

set -euo pipefail
NAME=${1:-wechat-api}

if ! docker ps -a --format '{{.Names}}' | grep -q "^${NAME}$"; then
  echo "容器 ${NAME} 不存在"
  exit 1
fi

echo "当前重启策略：$(docker inspect -f '{{ .HostConfig.RestartPolicy.Name }}' "$NAME")"
docker update --restart unless-stopped "$NAME"
echo "已设置为 unless-stopped"
