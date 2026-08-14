#!/bin/bash

sleep 5

curl -sfL https://get.k3s.io | K3S_URL="https://192.168.33.10:6443" \
    K3S_TOKEN="school21_static_token" \
    INSTALL_K3S_EXEC="agent --node-ip=$(hostname -I | awk '{print $2}')" sh -

sudo mkdir -p /mnt/data/postgres
sudo chmod 777 /mnt/data/postgres