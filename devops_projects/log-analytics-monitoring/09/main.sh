#!/bin/bash

# Часть 9. Собственный экспортёр метрик для Prometheus.
#
# Скрипт раз в 5 секунд перезаписывает файл в формате экспозиции Prometheus:
# строка HELP с описанием, строка TYPE с типом метрики, затем само значение.
# Формат намеренно тот же, что у node_exporter, — Prometheus не отличает
# источник и собирает метрики штатным way.
#
# Тип gauge выбран потому, что все три величины могут и расти, и убывать.
# Для счётчика, который только растёт, был бы counter.
#
# Файл отдаётся nginx'ом на отдельном порту, а Prometheus настроен ходить
# туда как за обычной целью — см. отчёт, часть 9.
#
# Запускается в фоне (в режиме демона) и работает, пока его не остановят.

METRICS_DIR="/var/www/metrics"
sudo mkdir -p "$METRICS_DIR"
sudo chown $USER:$USER "$METRICS_DIR"

METRICS_FILE="$METRICS_DIR/metrics.html"

while true; do
    metrics="# HELP node_sherryja_CPU_used_in_percent The total CPU used as percent value
# TYPE node_sherryja_CPU_used_in_percent gauge
node_sherryja_CPU_used_in_percent $(ps -eo pcpu | awk '{s+=$1} END {print s}')

# HELP node_sherryja_DISC_SPACE_free_in_bytes The total number of bytes free in home directory
# TYPE node_sherryja_DISC_SPACE_free_in_bytes gauge
node_sherryja_DISC_SPACE_free_in_bytes $(df -B1 /home | awk 'NR==2{print $4}')

# HELP node_sherryja_RAM_free_in_bytes The free RAM left in bytes
# TYPE node_sherryja_RAM_free_in_bytes gauge
node_sherryja_RAM_free_in_bytes $(free -b | awk 'NR==2{print $4}')"

    echo "$metrics" > $METRICS_FILE
    sleep 5
done