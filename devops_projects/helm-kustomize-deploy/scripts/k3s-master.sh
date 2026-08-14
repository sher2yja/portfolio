#!/bin/bash

curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server \
    --disable=traefik \
    --node-ip=192.168.33.10 \
    --token=school21_static_token" sh -

# Даем права обычному пользователю на kubectl, чтобы не писать sudo
mkdir -p /home/vagrant/.kube
sudo cp /etc/rancher/k3s/k3s.yaml /home/vagrant/.kube/config
sudo chown -R vagrant:vagrant /home/vagrant/.kube
if ! grep -q "KUBECONFIG" /home/vagrant/.bashrc; then
  echo 'export KUBECONFIG=$HOME/.kube/config' >> /home/vagrant/.bashrc
fi