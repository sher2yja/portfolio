#!/bin/bash
# log.sh — запись информации о созданных объектах и времени работы

# Функция логирования
# $1 — путь
# $2 — тип (dir/file)
log_object() {
  local path="$1"
  local type="$2"
  local log_file="${LOG_FILE:-$(dirname "$0")/log.txt}"
  local now=$(date '+%Y-%m-%d %H:%M:%S')
  local size="-"
  if [ "$type" = "file" ]; then
    size=$(stat -c %s "$path" 2>/dev/null)
  fi
  echo -e "$now\t$type\t$path\t$size" >> "$log_file"
} 