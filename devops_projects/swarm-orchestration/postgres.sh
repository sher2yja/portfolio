#!/bin/bash
# Подключение к базе внутри контейнера — команда для ручной проверки.
#
# Пароль не передаётся: psql запросит его интерактивно. Учётные данные
# стенда — postgres/postgres, они заданы в docker-compose.yml.

docker exec -it postgres psql -h localhost -p 5432 -U postgres -d postgres