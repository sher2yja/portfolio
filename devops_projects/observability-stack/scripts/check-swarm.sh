#!/bin/bash
# Сводка по состоянию кластера. Vagrantfile запускает её триггером после
# подъёма последней машины — так сразу видно, собрался кластер или нет,
# без ручного захода на менеджер.

set -e

echo "=== 🐳 Состояние Docker Swarm ==="
docker node ls

echo "=== 📦 Сервисы (если есть) ==="
docker service ls

echo "=== 🌐 Сети ==="
docker network ls

echo "=== ℹ️ Общая информация ==="
docker info --format 'Swarm: {{.Swarm.LocalNodeState}} | Nodes: {{.Swarm.Nodes}}'