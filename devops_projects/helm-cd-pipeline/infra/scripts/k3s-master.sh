#!/bin/bash
set -e

MASTER_IP="${1:?не передан IP мастера}"

# --disable=traefik            — вместо штатного контроллера ставится ingress-nginx
#                                (это делает deploy-app.sh). Тот же контроллер
#                                поднимается и в конвейере, поэтому правила Ingress
#                                на стенде и в CI ведут себя одинаково;
# --tls-san                    — иначе сертификат API не подходит для обращения
#                                с хоста по адресу ноды, и kubectl ругается на TLS;
# --write-kubeconfig-mode=644  — чтобы забрать kubeconfig на хост без sudo.
#
# Токен статический: узлы поднимаются параллельно, и агенту нужно значение,
# известное до старта сервера. Это локальный одноразовый стенд — за его
# пределами так делать нельзя.
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server \
    --disable=traefik \
    --node-ip=${MASTER_IP} \
    --tls-san=${MASTER_IP} \
    --write-kubeconfig-mode=644 \
    --token=helm_cd_local_token" sh -

# Права обычному пользователю на kubectl, чтобы не писать sudo внутри ноды
mkdir -p /home/vagrant/.kube
cp /etc/rancher/k3s/k3s.yaml /home/vagrant/.kube/config
chown -R vagrant:vagrant /home/vagrant/.kube
if ! grep -q "KUBECONFIG" /home/vagrant/.bashrc; then
  echo 'export KUBECONFIG=$HOME/.kube/config' >> /home/vagrant/.bashrc
fi
