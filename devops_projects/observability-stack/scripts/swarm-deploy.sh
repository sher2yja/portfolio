#!/bin/bash
# Разворачивание стеков — вариант с автоматическим запуском. Vagrantfile
# его не вызывает, разворачивание выполняется вручную через deploy.sh.
#
# Отличие: скрипт рассчитан на запуск при провижининге всех трёх машин
# сразу. На воркерах он сам определяет, что узел не менеджер, и выходит,
# а на менеджере ждёт, пока в кластер войдут все три узла, — иначе стек
# развернулся бы на одной машине, не дождавшись остальных.

status=$(docker info 2>/dev/null | grep "Is Manager: true")
if [ -z "$status" ]; then
  echo "Detected worker node. Skipping..."
  exit 0
fi

until [ $(docker node ls 2>/dev/null | grep -c "Ready") -eq 3 ]; do
  echo "Not all nodes are ready. Wait a bit..."
  sleep 2
done

docker network create --driver overlay --attachable hotel-overlay-net || true
cd /home/vagrant/app
docker stack deploy -c docker-compose.yml hotel-app
docker stack deploy -c docker-compose.portainer.yml portainer
docker stack deploy -c docker-compose.monitoring.yml monitoring