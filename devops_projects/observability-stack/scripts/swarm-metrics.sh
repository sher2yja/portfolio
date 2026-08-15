#!/bin/bash
# Собственный экспортёр метрик кластера: количество запущенных контейнеров,
# общее количество контейнеров и количество образов.
#
# Готового экспортёра для этих величин нет, но писать HTTP-сервер не нужно.
# node_exporter умеет отдавать содержимое файлов из каталога, указанного
# в --collector.textfile.directory, вместе со своими метриками. Достаточно
# положить туда текстовый файл в формате экспозиции Prometheus.
#
# Vagrantfile ставит запуск в cron раз в минуту — метрики обновляются
# независимо от того, опрашивает ли кто-то node_exporter в этот момент.
#
# Запись идёт во временный файл с последующим mv, а не напрямую в итоговый.
# mv в пределах одной файловой системы атомарен, поэтому node_exporter
# никогда не прочитает файл наполовину записанным и не отдаст обрезанную
# метрику. Прямая запись такую гонку допускает.

# Каталог по умолчанию — тот, что node_exporter читает внутри виртуальной
# машины. Вынесен в переменную, чтобы скрипт можно было проверить, не создавая
# системный каталог на рабочей машине: METRICS_DIR=/tmp/m ./swarm-metrics.sh
METRICS_DIR="${METRICS_DIR:-/var/lib/node_exporter/textfile_collector}"
TMP_FILE="${METRICS_DIR}/swarm.prom.tmp"
FINAL_FILE="${METRICS_DIR}/swarm.prom"

# Создаём директорию, если нет
mkdir -p "$METRICS_DIR"

# Считаем запущенные контейнеры
RUNNING=$(docker ps -q 2>/dev/null | wc -l)

# Считаем все контейнеры (включая stopped)
ALL=$(docker ps -aq 2>/dev/null | wc -l)

# Считаем образы
IMAGES=$(docker images -q 2>/dev/null | wc -l)

# Записываем метрики в формате экспозиции Prometheus: пара строк HELP и TYPE
# с описанием, затем само значение.
#
# Все три метрики — gauge, а не counter: значения могут и расти, и убывать.
# Counter описывает величину, которая только увеличивается, и суффикс _total
# в именах зарезервирован именно за ним. Поэтому здесь имена без _total —
# на первом варианте (swarm_containers_total, swarm_images_total)
# promtool check metrics выдавал предупреждение о несоответствии типа имени.
cat > "$TMP_FILE" << METRICS
# HELP swarm_containers_running Количество запущенных контейнеров
# TYPE swarm_containers_running gauge
swarm_containers_running $RUNNING
# HELP swarm_containers Все контейнеры, включая остановленные
# TYPE swarm_containers gauge
swarm_containers $ALL
# HELP swarm_images Количество Docker-образов на узле
# TYPE swarm_images gauge
swarm_images $IMAGES
METRICS

# Атомарно заменяем файл
mv "$TMP_FILE" "$FINAL_FILE"