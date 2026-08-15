#!/bin/bash
# Установка Docker — расширенный вариант, перенесён из задания по Docker Swarm.
# В этом стенде Vagrantfile его не вызывает, работает installdocker.sh.
#
# Отличие: помимо Docker настраивает вход по SSH между машинами — генерирует
# ключ, раскладывает known_hosts, включает вход по паролю. Это нужно тому
# способу входа в кластер, где воркер сам ходит на менеджер за токеном
# (join-swarm.sh). В текущей схеме токен передаётся через общую папку,
# поэтому SSH между машинами не требуется.
#
# ВНИМАНИЕ. Пароль vagrant:vagrant, PermitRootLogin yes и отключённая
# проверка ключа хоста допустимы только для одноразового локального стенда.

set -e

# Очистка противоречивых пакетов перед установкой
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
    sudo apt-get remove -y $pkg 2>/dev/null || true
done

sudo apt-get update
sudo apt-get install -y ca-certificates curl sshpass

# Добавляем официальный GPG ключ Docker
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Добавляем репозиторий
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update

# Основная установка
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo usermod -aG docker vagrant

# Включаем автозапуск
sudo systemctl enable docker
sudo systemctl start docker

echo "=== Настройка SSH ==="

sudo apt-get install -y openssh-server

# Настраиваем SSH для доступа по паролю
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo sed -i 's/PasswordAuthentication no/#PasswordAuthentication no/' /etc/ssh/sshd_config

# Разрешаем root логин по паролю
sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# Отключаем проверку хоста
sudo sed -i 's/#   StrictHostKeyChecking ask/StrictHostKeyChecking no/' /etc/ssh/ssh_config
echo "    StrictHostKeyChecking no" | sudo tee -a /etc/ssh/ssh_config

echo "vagrant:vagrant" | sudo chpasswd

sudo systemctl restart ssh

if [ ! -f /home/vagrant/.ssh/id_rsa ]; then
    sudo -u vagrant ssh-keygen -t rsa -N "" -f /home/vagrant/.ssh/id_rsa
fi

# Копируем публичный ключ в authorized_keys
sudo -u vagrant cat /home/vagrant/.ssh/id_rsa.pub >> /home/vagrant/.ssh/authorized_keys

# Добавляем known_hosts чтобы избежать проверки
KNOWN_HOSTS="/home/vagrant/.ssh/known_hosts"
sudo -u vagrant ssh-keyscan -H 192.168.56.10 >> $KNOWN_HOSTS 2>/dev/null
sudo -u vagrant ssh-keyscan -H 192.168.56.11 >> $KNOWN_HOSTS 2>/dev/null
sudo -u vagrant ssh-keyscan -H 192.168.56.12 >> $KNOWN_HOSTS 2>/dev/null

echo "=== SSH настроен для доступа между VM ==="

echo "=== Docker установлен ==="
docker --version
