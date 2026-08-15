#!/bin/bash
# Вход рабочего узла в Swarm. Вызывается Vagrantfile на worker01 и worker02.
#
# Порядок подъёма машин Vagrant не гарантирует, поэтому узел не ходит
# на менеджер, а ждёт появления файла с токеном в общей папке — до 60 секунд.
#
# Проверяется и существование файла, и его непустота: менеджер создаёт файл
# перенаправлением вывода, поэтому пустой файл появляется раньше, чем в него
# попадает токен. Без проверки на -s узел прочитал бы пустую строку.

set -e

TOKEN_PATH="/home/vagrant/app/scripts/swarm_token"

echo "[INFO] Ожидание появления токена..."

for i in {1..30}; do
  if [ -f "$TOKEN_PATH" ] && [ -s "$TOKEN_PATH" ]; then
    echo "[INFO] Токен найден"
    break
  fi
  echo "[INFO] Токен ещё не готов, жду... ($i/30)"
  sleep 2
done

if [ ! -f "$TOKEN_PATH" ] || [ ! -s "$TOKEN_PATH" ]; then
  echo "[ERROR] Токен не появился за 60 секунд"
  exit 1
fi

TOKEN=$(cat "$TOKEN_PATH")
echo "[INFO] Присоединение к Swarm как worker..."
docker swarm join --token "$TOKEN" 192.168.56.10:2377

echo "[INFO] Успешно присоединён к Swarm"