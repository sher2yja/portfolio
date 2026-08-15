#!/bin/bash

# Часть 3. Модуль цветного вывода.
#
# Файл предназначен только для подключения через source: он не выполняет
# работу сам, а объявляет функции для вызывающего скрипта. Сравнение
# BASH_SOURCE с $0 отличает эти два случая — при source значения не
# совпадают, при прямом запуске совпадают.
#
# Цвета задаются числами 1-6, а не ANSI-кодами: так проверка ввода сводится
# к сравнению двух чисел, а пользователю не нужно знать про escape-последовательности.

# color.sh — содержит функции и параметры цветов

# Если файл запущен напрямую, а не source-нут — выйти
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Файл должен быть подключен через source, а не запущен напрямую."
    exit 1
fi

# Проверка на количество параметров
if [ $# -ne 4 ]; then
    echo "Введите 4 параметра цифрами от 1 до 4:"
    echo "1.фон названий   "
    echo "2.цвет шрифта"
    echo "3.фон значений"
    echo "4.цвет шрифта значений"
    exit 1
fi

# Параметры цветов и фонов
background_names=$1
font_color_names=$2
background_values=$3
font_color_values=$4

# Проверка на совпадение цветов и фонов
if [ "$background_names" == "$font_color_names" ] || [ "$background_values" == "$font_color_values" ]; then
    echo "Ошибка: Цвета и фоны не могут совпадать."
    exit 1
fi

# Функция для вывода текста с заданными цветами и фонами
print_colored_text() {
    local text="$1"
    local background="$2"
    local font_color="$3"
    
    # ANSI escape коды для цвета и фона
    local bg_code=""
    local font_code=""
    case "$background" in
        1) bg_code="47";;
        2) bg_code="41";;
        3) bg_code="42";;
        4) bg_code="44";;
        5) bg_code="45";;
        6) bg_code="40";;
    esac

    case "$font_color" in
        1) font_code="97";;
        2) font_code="91";;
        3) font_code="92";;
        4) font_code="94";;
        5) font_code="95";;
        6) font_code="30";;
    esac

    echo -n -e "\e[${bg_code};${font_code}m${text}\e[0m"
}

# Функция для вывода названий и значений с заданными цветами и фонами на одной строке
print_colored_pair() {
    local name="$1"
    local value="$2"

    print_colored_text "$name = " "$background_names" "$font_color_names"
    print_colored_text "$value" "$background_values" "$font_color_values"
    echo
}