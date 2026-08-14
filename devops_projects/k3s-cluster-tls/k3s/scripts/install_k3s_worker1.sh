#!/bin/bash

# Подключение узла worker1 к кластеру. Запускается Vagrant'ом при vagrant up.
#
# Токен подключения генерирует мастер, поэтому скрипт ждёт файл в цикле:
# Vagrant поднимает машины последовательно, но провижининг воркера может
# начаться раньше, чем мастер допишет /vagrant/token. Без ожидания воркер
# упал бы на первом запуске и кластер пришлось бы досоздавать вручную.
#
# /vagrant - общий каталог, в него смонтирована папка k3s/ с хоста.

set -e

MASTER_IP="192.168.56.10"
WORKER_IP="192.168.56.11"

apt-get update -y
echo "Установка curl"
apt-get install -y curl

echo "Ждем токен...."
while [ ! -f /vagrant/token ]; do
  sleep 5
done

NODE_TOKEN=$(cat /vagrant/token)

echo "Подключаемся к Мастеру"

curl -sfL https://get.k3s.io | \
K3S_URL="https://${MASTER_IP}:6443" \
K3S_TOKEN="${NODE_TOKEN}" \
INSTALL_K3S_EXEC="agent \
  --node-ip=${WORKER_IP} \
  --flannel-iface=eth1" \
sh -

echo "Воркер подключен успешно"