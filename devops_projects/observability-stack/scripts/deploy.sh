#!/bin/bash
# Разворачивание всех трёх стеков. Запускается вручную на manager01
# после того, как кластер собран.
#
# Оверлейная сеть создаётся до стеков и объявлена в compose-файлах как
# external: все три стека должны попасть в одну сеть, а если бы её создавал
# сам стек, каждый получил бы свою и сервисы не увидели бы друг друга.
# Флаг --attachable позволяет подключать к ней и обычные контейнеры,
# запущенные вне Swarm, — удобно при отладке.

cd /home/vagrant/app
docker network create --driver overlay --attachable hotel-overlay-net
docker stack deploy -c docker-compose.yml hotel-app
docker stack deploy -c docker-compose.portainer.yml portainer
#теперь излишний
#docker stack deploy -c docker-compose.loki.yml loki-stack
docker stack deploy -c docker-compose.monitoring.yml monitoring
docker service ls
docker stack ls
