#!/bin/bash
# Вход воркера в Swarm — альтернативный вариант, перенесён из задания
# по Docker Swarm. В этом стенде Vagrantfile его не вызывает, работает join.sh.
#
# Отличие: токен не читается из общей папки, а запрашивается у менеджера
# по SSH. Способ не требует общей папки, но требует настроенного доступа
# по SSH (его готовит install-docker.sh) и паролей в открытом виде.

set -e

# Добавляем manager в known_hosts чтобы избежать проверки
sudo -u vagrant ssh-keyscan -H 192.168.56.10 >> /home/vagrant/.ssh/known_hosts 2>/dev/null

COUNT=0
while [ $COUNT -lt 180 ]; do
    SWARM_TOKEN=$(sshpass -p 'vagrant' ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 vagrant@192.168.56.10 "docker swarm join-token worker -q 2>/dev/null" 2>/dev/null || echo "")
    MANAGER_IP="192.168.56.10"

    if [ -n "$SWARM_TOKEN" ]; then
        echo "✅ Токен получен от manager: $SWARM_TOKEN"
        break
    fi

    echo "Ожидание manager... ($COUNT сек)"
    sleep 10
    COUNT=$((COUNT + 10))
done

if [ -z "$SWARM_TOKEN" ]; then
    echo "❌ Не удалось получить токен за 180 секунд"
    exit 1
fi

docker swarm join --token $SWARM_TOKEN $MANAGER_IP:2377

if [ $? -eq 0 ]; then
    echo "=== УСПЕШНО присоединились к Swarm ==="
else
    echo "=== ОШИБКА подключения к Swarm ==="
    exit 1
fi
