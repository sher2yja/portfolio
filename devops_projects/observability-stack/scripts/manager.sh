#!/bin/bash
# Инициализация Swarm на manager01. Вызывается Vagrantfile.
#
# Проверка «Swarm уже активен» позволяет запускать провижининг повторно:
# docker swarm init на уже инициализированном узле завершается ошибкой
# и из-за set -e уронил бы весь vagrant up.
#
# Токен для входа воркеров сохраняется в общую папку, смонтированную на всех
# трёх машинах. Отсюда его читает join.sh. Сам файл токена в репозиторий
# не выкладывается — он генерируется здесь при каждом подъёме кластера.

set -e

echo "[INFO] Проверка: Swarm уже инициализирован?"
if docker info | grep -q "Swarm: active"; then
  echo "[INFO] Swarm уже активен"
else
  echo "[INFO] Инициализация Docker Swarm..."
  docker swarm init --advertise-addr 192.168.56.10
fi

echo "[INFO] Сохранение worker-токена..."
mkdir -p /home/vagrant/app/scripts
docker swarm join-token -q worker > /home/vagrant/app/scripts/swarm_token

echo "[INFO] Токен сохранён. Список нод:"
docker node ls