#!/bin/bash
# generate_log.sh — генерация одного файла лога за 1 день

source "$(dirname "$0")/utils.sh"

# $1 — номер дня (1..5)

# Определяем дату (последние 5 дней от сегодня)
BASE_DATE=$(date -d "$((4-$1)) days ago" +%Y-%m-%d)
LOG_FILE="$(dirname "$0")/nginx_log_${BASE_DATE}.log"

# Генерируем случайное число записей (100-1000)
NUM_RECORDS=$((RANDOM % 901 + 100))

for ((i=0; i<$NUM_RECORDS; i++)); do
  ip=$(random_ip)
  method=$(random_method)
  code=$(random_code)
  url=$(random_url)
  agent=$(random_agent)
  time=$(random_time "$BASE_DATE" "$i")
  size=$((RANDOM % 5000 + 200))
  referer="-"
  # Формат nginx combined:
  # $remote_addr - - [$time_local] "$request" $status $body_bytes_sent "$http_referer" "$http_user_agent"
  echo "$ip - - [$time] \"$method $url HTTP/1.1\" $code $size \"$referer\" \"$agent\"" >> "$LOG_FILE"
done