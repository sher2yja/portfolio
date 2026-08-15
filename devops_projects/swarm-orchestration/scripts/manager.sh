#!/bin/bash
# Инициализация Swarm на менеджере. Вызывается Vagrantfile.
#
# Проверка «Swarm уже активен» позволяет запускать провижининг повторно:
# docker swarm init на уже инициализированном узле завершается ошибкой,
# и из-за set -e это уронило бы весь vagrant up.
#
# --advertise-addr обязателен: у машины два интерфейса — NAT от Vagrant
# и приватная сеть стенда. Без явного указания Swarm выбирает адрес сам
# и нередко берёт NAT-овский, по которому соседние узлы до него не дойдут.

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