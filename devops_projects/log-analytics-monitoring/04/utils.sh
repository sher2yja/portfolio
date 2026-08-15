#!/bin/bash
# utils.sh — вспомогательные функции для генерации логов

# Функция генерации случайного IP-адреса
random_ip() {
  echo "$((RANDOM%256)).$((RANDOM%256)).$((RANDOM%256)).$((RANDOM%256))"
}

# Функция генерации случайного метода
random_method() {
  local methods=(GET POST PUT PATCH DELETE)
  echo "${methods[$RANDOM % ${#methods[@]}]}"
}

# Функция генерации случайного кода ответа
random_code() {
  local codes=(
    200 # Успешно
    201 # Создано
    400 # Неверный запрос
    401 # Не авторизован
    403 # Доступ запрещён
    404 # Не найдено
    500 # Внутренняя ошибка сервера
    501 # Не реализовано
    502 # Плохой шлюз
    503 # Сервис недоступен
  )
  echo "${codes[$RANDOM % ${#codes[@]}]}"
}

# Функция генерации случайного URL
random_url() {
  local urls=(/ /index.html /about /contact /products /api/data /login /logout /admin /search?q=test)
  echo "${urls[$RANDOM % ${#urls[@]}]}"
}

# Функция генерации случайного User-Agent
random_agent() {
  local agents=(
    "Mozilla/5.0"
    "Google Chrome/91.0"
    "Opera/9.80"
    "Safari/537.36"
    "Internet Explorer/11.0"
    "Microsoft Edge/18.18363"
    "Crawler and bot/1.0"
    "Library and net tool/2.0"
  )
  echo "${agents[$RANDOM % ${#agents[@]}]}"
}

# Функция генерации случайного времени в рамках дня (возвращает HH:MM:SS, увеличивается на каждом вызове)
# $1 — базовая дата (например, 2025-07-20)
# $2 — номер записи (для увеличения времени)
random_time() {
  local base_date="$1"
  local idx="$2"
  local seconds=$((idx * 60 + RANDOM % 60))
  # Проверка на пустую дату
  if [[ -z "$base_date" ]]; then
    date '+%d/%b/%Y:%H:%M:%S +0300'
    return
  fi
  local result
  result=$(date -d "${base_date} 00:00:00 +${seconds} seconds" '+%d/%b/%Y:%H:%M:%S +0300' 2>/dev/null)
  if [[ -z "$result" ]]; then
    # Если не удалось сгенерировать дату, вернуть текущую
    date '+%d/%b/%Y:%H:%M:%S +0300'
  else
    echo "$result"
  fi
}