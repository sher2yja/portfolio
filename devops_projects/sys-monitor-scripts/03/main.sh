#!/bin/bash

# Часть 3. Вывод сведений о системе с цветами из аргументов.
#
# Отличие от части 2 — не в собираемых данных, а в способе вывода: значения
# печатаются сразу, парами «название = значение», через функции из colors.sh.
# Промежуточной переменной OUTPUT здесь нет, потому что сохранение в файл
# в этой части не требуется.
#
# Аргументы командной строки передаются в модуль как есть: source colors.sh "$@"

# Проверка наличия ipcalc.
#
# Раньше здесь разбирался текст ошибки — grep искал строку
# "Command 'ipcalc' not found". Это не работает: такое сообщение печатает
# обработчик command-not-found, который подключается только в интерактивной
# оболочке. Внутри скрипта bash пишет "ipcalc: command not found", шаблон не
# совпадал, признак оставался положительным, и таблица ниже не срабатывала.
# command -v проверяет наличие команды напрямую и от текста сообщений не зависит.
if command -v ipcalc >/dev/null 2>&1; then
    IPCALC_INSTALLED=true
else
    IPCALC_INSTALLED=false
fi

# Подключение цветового модуля
source colors.sh "$@"

# Собираем информацию и выводим с заданными цветами и фонами
print_colored_pair "HOSTNAME" "$(hostname)"
print_colored_pair "TIMEZONE" "$(timedatectl show --property=Timezone --value) UTC $(date +%:z | sed 's/^\([+-]\)[0]*\([0-9]\{1,2\}\):[0-9]\{2\}$/\1\2/')"
print_colored_pair "USER" "$(whoami)"
print_colored_pair "OS" "$(grep '^PRETTY_NAME=' /etc/os-release | cut -d= -f2 | tr -d '"')"
print_colored_pair "DATE" "$(LC_TIME=C date "+%d %B %Y %T")"
print_colored_pair "UPTIME" "$(uptime -p | sed 's/^up //')"
print_colored_pair "UPTIME_SEC" "$(cat /proc/uptime | awk '{printf "%.0f", $1}') sec."
print_colored_pair "IP" "$(ip -4 addr show | grep inet | awk '{print $2}' | cut -d '/' -f1 | head -n 1)"
CIDR_MASK=$(ip -4 addr show | grep inet | awk '{print $2}' | cut -d '/' -f2 | head -n 1)
if $IPCALC_INSTALLED; then
print_colored_pair "MASK" "$(ipcalc 0.0.0.0/"$CIDR_MASK" | awk '/Netmask:/ {print $2}')"
else
case "$CIDR_MASK" in
        0)  MASK="0.0.0.0" ;;
        1)  MASK="128.0.0.0" ;;
        2)  MASK="192.0.0.0" ;;
        3)  MASK="224.0.0.0" ;;
        4)  MASK="240.0.0.0" ;;
        5)  MASK="248.0.0.0" ;;
        6)  MASK="252.0.0.0" ;;
        7)  MASK="254.0.0.0" ;;
        8)  MASK="255.0.0.0" ;;
        9)  MASK="255.128.0.0" ;;
        10) MASK="255.192.0.0" ;;
        11) MASK="255.224.0.0" ;;
        12) MASK="255.240.0.0" ;;
        13) MASK="255.248.0.0" ;;
        14) MASK="255.252.0.0" ;;
        15) MASK="255.254.0.0" ;;
        16) MASK="255.255.0.0" ;;
        17) MASK="255.255.128.0" ;;
        18) MASK="255.255.192.0" ;;
        19) MASK="255.255.224.0" ;;
        20) MASK="255.255.240.0" ;;
        21) MASK="255.255.248.0" ;;
        22) MASK="255.255.252.0" ;;
        23) MASK="255.255.254.0" ;;
        24) MASK="255.255.255.0" ;;
        25) MASK="255.255.255.128" ;;
        26) MASK="255.255.255.192" ;;
        27) MASK="255.255.255.224" ;;
        28) MASK="255.255.255.240" ;;
        29) MASK="255.255.255.248" ;;
        30) MASK="255.255.255.252" ;;
        31) MASK="255.255.255.254" ;;
        32) MASK="255.255.255.255" ;;
        esac
# Значение вычислено таблицей выше — его нужно передать вторым аргументом.
# Без него функция печатала только название, а маска терялась
print_colored_pair "MASK" "$MASK"
fi
print_colored_pair "GATEWAY" "$(ip route | grep default | awk '{print $3}')"
print_colored_pair "RAM_TOTAL" "$(free -m | awk '/Mem:/ {printf "%.3f GB", $2/1024}')"
print_colored_pair "RAM_USED" "$(free -m | awk '/Mem:/ {printf "%.3f GB", $3/1024}')"
print_colored_pair "RAM_FREE" "$(free -m | awk '/Mem:/ {printf "%.3f GB", $4/1024}')"
print_colored_pair "SPACE_ROOT" "$(df -k / | awk '/\// {printf "%.2f MB", $2/1024}')"
print_colored_pair "SPACE_ROOT_USED" "$(df -k / | awk '/\// {printf "%.2f MB", $3/1024}')"
print_colored_pair "SPACE_ROOT_FREE" "$(df -k / | awk '/\// {printf "%.2f MB", $4/1024}')"