#!/bin/bash
# Установка Docker Engine. Вызывается Vagrantfile на всех трёх машинах.
#
# Скрипт идемпотентный: при повторном provision он видит уже установленный
# Docker и выходит, ничего не трогая. Это важно, потому что провижининг
# запускается заново при каждом vagrant up остановленной машины.
#
# sudo не нужен: Vagrant выполняет shell-провижининг от root.

set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

# Проверка: Docker уже установлен?
if command -v docker &> /dev/null; then
  echo "[INFO] Docker уже установлен"
  docker --version
  exit 0
fi

echo "[INFO] Обновление системы и установка зависимостей..."
apt-get update
apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release

echo "[INFO] Добавление GPG-ключа Docker..."
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo "[INFO] Добавление репозитория Docker..."
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "[INFO] Установка Docker Engine и Compose Plugin..."
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

echo "[INFO] Настройка пользователя vagrant для работы с Docker без sudo..."
usermod -aG docker vagrant

echo "[INFO] Включение и запуск службы Docker..."
systemctl enable docker
systemctl start docker

echo "[INFO] Проверка установки:"
docker --version
docker compose version