#!/bin/bash

# Часть 2. Сбор сведений о системе.
#
# Пятнадцать параметров машины собираются штатными утилитами: hostname,
# timedatectl, /etc/os-release, uptime, ip, free, df. Данные сначала
# складываются в одну переменную OUTPUT и только потом печатаются — так один
# и тот же текст попадает и на экран, и в файл, без повторного сбора.
#
# Маска подсети требует преобразования: ip выдаёт префикс (/24), а нужна
# полная форма (255.255.255.0). Если в системе есть ipcalc, перевод делает
# он; иначе срабатывает таблица соответствий на 33 значения.
#
# Имя файла для сохранения собирается из отметки времени, поэтому повторные
# запуски не затирают друг друга.

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

# Собираю информацию
HOSTNAME=$(hostname)
TIMEZONE=$(timedatectl show --property=Timezone --value)
UTC_OFFSET=$(date +%:z | sed 's/^\([+-]\)[0]*\([0-9]\{1,2\}\):[0-9]\{2\}$/\1\2/')
USER=$(whoami)
OS=$(grep '^PRETTY_NAME=' /etc/os-release | cut -d= -f2 | tr -d '"')
DATE=$(date "+%d %B %Y %T")
UPTIME=$(uptime -p | sed 's/^up //')
UPTIME_SEC=$(cat /proc/uptime | awk '{printf "%.0f", $1}')
IP=$(ip -4 addr show | grep inet | awk '{print $2}' | cut -d '/' -f1 | head -n 1)
# Маска подсети (преобразование CIDR в полную маску)
CIDR_MASK=$(ip -4 addr show | grep inet | awk '{print $2}' | cut -d '/' -f2 | head -n 1)
if $IPCALC_INSTALLED; then
MASK=$(ipcalc 0.0.0.0/"$CIDR_MASK" | awk '/Netmask:/ {print $2}') 
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
fi
GATEWAY=$(ip route | grep default | awk '{print $3}')
RAM_TOTAL=$(free -m | awk '/Mem:/ {printf "%.3f GB", $2/1024}')
RAM_USED=$(free -m | awk '/Mem:/ {printf "%.3f GB", $3/1024}')
RAM_FREE=$(free -m | awk '/Mem:/ {printf "%.3f GB", $4/1024}')
SPACE_ROOT=$(df -k / | awk '/\// {printf "%.2f MB", $2/1024}')
SPACE_ROOT_USED=$(df -k / | awk '/\// {printf "%.2f MB", $3/1024}')
SPACE_ROOT_FREE=$(df -k / | awk '/\// {printf "%.2f MB", $4/1024}')

# Формирую вывод в одну переменную
OUTPUT="HOSTNAME = $HOSTNAME
TIMEZONE = $TIMEZONE UTC $UTC_OFFSET
USER = $USER
OS = $OS
DATE = $DATE
UPTIME = $UPTIME
UPTIME_SEC = $UPTIME_SEC sec.
IP = $IP
MASK = $MASK
GATEWAY = $GATEWAY
RAM_TOTAL = $RAM_TOTAL
RAM_USED = $RAM_USED
RAM_FREE = $RAM_FREE
SPACE_ROOT = $SPACE_ROOT
SPACE_ROOT_USED = $SPACE_ROOT_USED
SPACE_ROOT_FREE = $SPACE_ROOT_FREE"

echo "$OUTPUT"

# Сохраняю в файл, если пользователь ответил Y/y
read -p "Сохранить данные в файл (Y/N)? " choice
if [ "$choice" == "Y" ] || [ "$choice" == "y" ]; then
    TIMESTAMP=$(date +"%d_%m_%y_%H_%M_%S")
    FILENAME="${TIMESTAMP}.status"
    echo "$OUTPUT" > "$FILENAME"
    echo "Данные сохранены в файл $FILENAME"
else
    echo "Данные не сохранены."
fi