#!/bin/bash
# Сводка по состоянию кластера: узлы, сервисы, сети.
# Запускается триггером Vagrant после подъёма последней машины.

set -e

echo "=== 🐳 Состояние Docker Swarm ==="
docker node ls

echo "=== 📦 Сервисы (если есть) ==="
docker service ls

echo "=== 🌐 Сети ==="
docker network ls

echo "=== ℹ️ Общая информация ==="
docker info --format 'Swarm: {{.Swarm.LocalNodeState}} | Nodes: {{.Swarm.Nodes}}'