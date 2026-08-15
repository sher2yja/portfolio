#!/bin/bash

# Часть 9. Собственный экспортёр метрик для Prometheus.
#
# Скрипт раз в 5 секунд перезаписывает файл в формате экспозиции Prometheus:
# строка HELP с описанием, строка TYPE с типом метрики, затем само значение.
# Формат намеренно тот же, что у node_exporter, — Prometheus не отличает
# источник и собирает такие метрики наравне со штатными.
#
# Тип gauge выбран потому, что все три величины могут и расти, и убывать.
# Для счётчика, который только растёт, был бы counter.
#
# Файл отдаётся nginx'ом на отдельном порту, а Prometheus настроен ходить
# туда как за обычной целью — см. отчёт, часть 9.
#
# Запускается в фоне (в режиме демона) и работает, пока его не остановят.

# Каталог по умолчанию — тот, что раздаёт nginx на отдельном порту.
# Вынесен в переменную, чтобы скрипт можно было проверить, не создавая
# системный каталог и не спрашивая пароль:
#   METRICS_DIR=/tmp/m ./main.sh
#
# Прежняя версия делала это безусловно и через sudo:
#     sudo mkdir -p /var/www/metrics
#     sudo chown $USER:$USER /var/www/metrics
# Запуск требовал ввода пароля, а на машине оставался системный каталог,
# который потом удаляется только через sudo. Здесь каталог создаётся
# обычными правами: если их не хватает, скрипт скажет об этом и выйдет,
# а не оставит систему в неожиданном состоянии.
METRICS_DIR="${METRICS_DIR:-/var/www/metrics}"

if ! mkdir -p "$METRICS_DIR" 2>/dev/null; then
    echo "Не удалось создать каталог $METRICS_DIR — нет прав." >&2
    echo "Укажите другой путь: METRICS_DIR=~/metrics $0" >&2
    echo "Либо подготовьте каталог заранее:" >&2
    echo "    sudo mkdir -p $METRICS_DIR && sudo chown \"\$USER\" $METRICS_DIR" >&2
    exit 1
fi

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

    echo "$metrics" > "$METRICS_FILE"
    sleep 5
done