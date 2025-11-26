#!/bin/bash
# 监控脚本：检查 wechat-api 健康状态，不健康则重启并记录；配合 crontab 每5分钟执行
# 用法：bash scripts/monitor-wechat-api.sh [container_name]
# 环境变量配置（可选）：ALERT_EMAIL_ENABLED, SMTP_SERVER, SMTP_PORT, SMTP_USER, SMTP_PASS, ALERT_EMAIL_TO

set -euo pipefail
CONTAINER_NAME=${1:-wechat-api}
LOG_FILE=/var/log/wechat-api-monitor.log
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# 邮件告警配置（从环境变量读取，默认启用）
ALERT_EMAIL_ENABLED=${ALERT_EMAIL_ENABLED:-true}
SMTP_SERVER=${SMTP_SERVER:-smtp.139.com}
SMTP_PORT=${SMTP_PORT:-25}
SMTP_USER=${SMTP_USER:-qsoft@139.com}
SMTP_PASS=${SMTP_PASS:-574a283d502db51ea200}
ALERT_EMAIL_TO=${ALERT_EMAIL_TO:-qsoft@139.com}

mkdir -p "$(dirname "$LOG_FILE")" || true

log() {
  echo "[$TIMESTAMP] $1" | tee -a "$LOG_FILE"
}

send_email() {
  local subject="$1"
  local body="$2"
  
  if [ "$ALERT_EMAIL_ENABLED" != "true" ] || [ -z "$SMTP_USER" ] || [ -z "$SMTP_PASS" ] || [ -z "$ALERT_EMAIL_TO" ]; then
    return 0
  fi
  
  # 使用 sendmail 或 curl 发送邮件
  if command -v curl >/dev/null 2>&1; then
    local email_content="From: ${SMTP_USER}
To: ${ALERT_EMAIL_TO}
Subject: ${subject}
Date: $(date -R)

${body}"
    
    echo "$email_content" | curl -s --url "smtp://${SMTP_SERVER}:${SMTP_PORT}" \
      --mail-from "${SMTP_USER}" \
      --mail-rcpt "${ALERT_EMAIL_TO}" \
      --user "${SMTP_USER}:${SMTP_PASS}" \
      --upload-file - >/dev/null 2>&1 || log "邮件发送失败"
  fi
}

notify() {
  local message="$1"
  log "$message"
  send_email "[WeChat API 告警] ${CONTAINER_NAME}" "$message

时间: $TIMESTAMP
容器: $CONTAINER_NAME
主机: $(hostname)

请及时检查服务状态。"
}

if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  log "容器未运行，尝试启动..."
  docker start "${CONTAINER_NAME}" >/dev/null 2>&1 || true
  sleep 5
fi

HEALTH=$(docker inspect -f '{{ if .State.Health }}{{ .State.Health.Status }}{{ else }}unknown{{ end }}' "${CONTAINER_NAME}" 2>/dev/null || echo "unknown")
if [ "$HEALTH" = "healthy" ]; then
  log "容器健康(healthy)"
  exit 0
fi

# 二次校验：优先容器内探测，否则回退宿主探测 8092
if docker exec "${CONTAINER_NAME}" sh -c 'which curl >/dev/null 2>&1 && curl -kfsS https://localhost:8082/api/health >/dev/null' 2>/dev/null; then
  log "端点健康，但Docker Health=\"$HEALTH\"，可能健康检查延迟"
  exit 0
fi
if command -v curl >/dev/null 2>&1 && curl -kfsS https://localhost:8092/api/health >/dev/null 2>&1; then
  log "宿主端口 8092 健康，容器健康状态=$HEALTH（可能无 HEALTHCHECK 或延迟）"
  exit 0
fi

log "检测到容器不健康(Health=$HEALTH)，执行重启..."
docker restart "${CONTAINER_NAME}" >/dev/null 2>&1 || true
sleep 8

# 重启后再次检查（容器内优先，其次宿主）
if docker exec "${CONTAINER_NAME}" sh -c 'which curl >/dev/null 2>&1 && curl -kfsS https://localhost:8082/api/health >/dev/null' 2>/dev/null \
   || (command -v curl >/dev/null 2>&1 && curl -kfsS https://localhost:8092/api/health >/dev/null 2>&1); then
  log "重启后恢复正常"
  notify "wechat-api异常已自动重启恢复"
  exit 0
else
  log "重启后仍异常，请人工介入"
  notify "wechat-api重启后仍异常，请排查"
  exit 1
fi
