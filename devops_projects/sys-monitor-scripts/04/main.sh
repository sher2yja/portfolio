#!/bin/bash

# Часть 4. Вывод сведений о системе с цветами из конфигурационного файла.
#
# От части 3 отличается источником настроек: вместо четырёх аргументов
# командной строки вызывается load_config, читающий config.conf.
#
# В конце печатается использованная цветовая схема — по ней видно, какие
# значения взяты из файла, а какие остались по умолчанию.

# Подключаем цветовые функции
source "./colors.sh"

# Перевод префикса в полную маску без внешних утилит.
#
# В частях 2 и 3 то же самое сделано таблицей на 33 значения; здесь маска
# считается арифметикой, чтобы не дублировать таблицу третий раз.
# Из 32 единиц гасятся младшие (32 - префикс) разрядов, дальше число
# разбирается на октеты сдвигами.
cidr_to_mask() {
    local bits=$(( 0xffffffff ^ ((1 << (32 - $1)) - 1) ))
    printf "%d.%d.%d.%d" $(( bits >> 24 & 255 )) $(( bits >> 16 & 255 )) \
                         $(( bits >> 8 & 255 ))  $(( bits & 255 ))
}

# Основная часть скрипта
load_config

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
if command -v ipcalc >/dev/null 2>&1; then
    print_colored_pair "MASK" "$(ipcalc 0.0.0.0/"$CIDR_MASK" | awk '/Netmask:/ {print $2}')"
else
    print_colored_pair "MASK" "$(cidr_to_mask "$CIDR_MASK")"
fi
print_colored_pair "GATEWAY" "$(ip route | grep default | awk '{print $3}')"
print_colored_pair "RAM_TOTAL" "$(free -m | awk '/Mem:/ {printf "%.3f GB", $2/1024}')"
print_colored_pair "RAM_USED" "$(free -m | awk '/Mem:/ {printf "%.3f GB", $3/1024}')"
print_colored_pair "RAM_FREE" "$(free -m | awk '/Mem:/ {printf "%.3f GB", $4/1024}')"
print_colored_pair "SPACE_ROOT" "$(df -k / | awk '/\// {printf "%.2f MB", $2/1024}')"
print_colored_pair "SPACE_ROOT_USED" "$(df -k / | awk '/\// {printf "%.2f MB", $3/1024}')"
print_colored_pair "SPACE_ROOT_FREE" "$(df -k / | awk '/\// {printf "%.2f MB", $4/1024}')"

# Выводим информацию о цветовой схеме
print_color_scheme