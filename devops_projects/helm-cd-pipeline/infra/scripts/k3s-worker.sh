#!/bin/bash
set -e

MASTER_IP="${1:?не передан IP мастера}"

# Ждём, пока сервер k3s на мастере поднимет API: агент, стартовавший раньше,
# уходит в цикл переподключений и нода появляется в кластере с задержкой.
for i in $(seq 1 60); do
  curl -sk "https://${MASTER_IP}:6443/ping" >/dev/null 2>&1 && break
  sleep 5
done

# Второй интерфейс — это адрес приватной сети из Vagrantfile; первый принадлежит
# NAT-сети libvirt и для внутрикластерного трафика не годится.
NODE_IP="$(hostname -I | awk '{print $2}')"

curl -sfL https://get.k3s.io | K3S_URL="https://${MASTER_IP}:6443" \
    K3S_TOKEN="helm_cd_local_token" \
    INSTALL_K3S_EXEC="agent --node-ip=${NODE_IP}" sh -
