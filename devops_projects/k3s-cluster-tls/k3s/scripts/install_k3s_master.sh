#!/bin/bash

# Установка k3s server на узел master. Запускается Vagrant'ом при vagrant up.
#
# Два флага, без которых стенд не работает:
#   --disable traefik   штатный Ingress-контроллер k3s отключается, вместо
#                       него отдельно ставится ingress-nginx (требование задачи)
#   --flannel-iface=eth1  у VM два интерфейса: eth0 - NAT, одинаковый у всех
#                       трёх машин, и eth1 - private network со статическим IP.
#                       Без явного указания Flannel может выбрать eth0, и поды
#                       на разных узлах перестанут видеть друг друга. При этом
#                       kubectl get nodes покажет здоровый кластер - симптом
#                       на сетевую проблему не похож.
#
# --write-kubeconfig-mode=644 открывает kubeconfig обычному пользователю,
# иначе каждая команда kubectl требует sudo.

set -e
apt-get update -y
echo "Установка curl"
apt-get install -y curl
echo "Установка k3s (without Traefik)..."
curl -sfL https://get.k3s.io | \
INSTALL_K3S_EXEC="server \
  --node-ip=192.168.56.10 \
  --advertise-address=192.168.56.10 \
  --cluster-cidr=10.42.0.0/16 \
  --service-cidr=10.43.0.0/16 \
  --disable traefik \
  --flannel-iface=eth1 \
  --write-kubeconfig-mode=644" \
sh -

echo "Ждем 30 сек"
sleep 30
echo "Проверка запуска k3s"
systemctl status k3s --no-pager

echo "Копируем токен"
TOKEN=$(sudo cat /var/lib/rancher/k3s/server/node-token)
echo $TOKEN > /vagrant/token

echo "Export KUBECONFIG"
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
echo "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml" >> ~/.bashrc

kubectl get nodes