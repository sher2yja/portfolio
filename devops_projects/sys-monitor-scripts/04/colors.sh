#!/bin/bash

# Часть 4. Модуль цветного вывода с конфигурационным файлом.
#
# Развитие модуля из части 3: цвета берутся не из аргументов, а из config.conf,
# и у каждого параметра есть значение по умолчанию на случай, если файл
# отсутствует или в нём заполнено не всё.
#
# Разбор конфига сделан построчным чтением с фильтрацией комментариев и
# пробелов, а не через source: подключать конфиг как код опасно — любая
# строка в файле выполнилась бы с правами скрипта.
#
# Функция print_color_scheme дополнительно помечает словом default те
# значения, которые пользователь не переопределял.

# Конфигурационный файл
CONFIG_FILE="config.conf"

# Цветовая схема по умолчанию
DEFAULT_COLUMN1_BACKGROUND=6
DEFAULT_COLUMN1_FONT_COLOR=1
DEFAULT_COLUMN2_BACKGROUND=2
DEFAULT_COLUMN2_FONT_COLOR=4

# Функция для загрузки параметров из конфигурационного файла
load_config() {
    # Сброс переменных
    unset column1_background column1_font_color column2_background column2_font_color 2>/dev/null

    if [ -f "$CONFIG_FILE" ]; then
        # Читаем файл построчно
        while IFS='=' read -r key value || [ -n "$key" ]; do
            # Пропускаем пустые строки и комментарии
            [ -z "$key" ] && continue
            [[ "$key" =~ ^[[:space:]]*# ]] && continue
            
            # Удаляем лишние пробелы и кавычки
            key=$(echo "$key" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
            value=$(echo "$value" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//; s/^["'\'']\(.*\)["'\'']$/\1/')
            
            # Устанавливаем переменные
            case "$key" in
                column1_background) column1_background="$value" ;;
                column1_font_color) column1_font_color="$value" ;;
                column2_background) column2_background="$value" ;;
                column2_font_color) column2_font_color="$value" ;;
            esac
        done < "$CONFIG_FILE"
    fi

    # Устанавливаем значения по умолчанию
    column1_background=${column1_background:-$DEFAULT_COLUMN1_BACKGROUND}
    column1_font_color=${column1_font_color:-$DEFAULT_COLUMN1_FONT_COLOR}
    column2_background=${column2_background:-$DEFAULT_COLUMN2_BACKGROUND}
    column2_font_color=${column2_font_color:-$DEFAULT_COLUMN2_FONT_COLOR}

    # Проверка на совпадение цветов
    if [ "$column1_background" == "$column1_font_color" ] || [ "$column2_background" == "$column2_font_color" ]; then
        echo "Ошибка: Цвета и фоны не могут совпадать."
        exit 1
    fi
}

# Функция для получения названия цвета
get_color_name() {
    case "$1" in
        1) echo "white";;
        2) echo "red";;
        3) echo "green";;
        4) echo "blue";;
        5) echo "purple";;
        6) echo "black";;
        *) echo "unknown";;
    esac
}

# Функция для вывода текста с заданными цветами и фонами
print_colored_text() {
    local text="$1"
    local background="$2"
    local font_color="$3"
    
    # ANSI escape коды для цвета и фона
    local bg_code=""
    local font_code=""
    case "$background" in
        1) bg_code="47";;  # белый фон
        2) bg_code="41";;  # красный фон
        3) bg_code="42";;  # зеленый фон
        4) bg_code="44";;  # синий фон
        5) bg_code="45";;  # пурпурный фон
        6) bg_code="40";;  # черный фон
    esac

    case "$font_color" in
        1) font_code="97";;  # белый текст
        2) font_code="91";;  # красный текст
        3) font_code="92";;  # зеленый текст
        4) font_code="94";;  # синий текст
        5) font_code="95";;  # пурпурный текст
        6) font_code="30";;  # черный текст
    esac

    echo -n -e "\e[${bg_code};${font_code}m${text}\e[0m"
}

# Функция для вывода названий и значений с заданными цветами и фонами на одной строке
print_colored_pair() {
    local name="$1"
    local value="$2"

    print_colored_text "$name = " "$column1_background" "$column1_font_color"
    print_colored_text "$value" "$column2_background" "$column2_font_color"
    echo
}

# Функция для вывода информации о цветовой схеме
print_color_scheme() {
    echo
    echo -n "Column 1 background = "
    if [ "$column1_background" -eq "$DEFAULT_COLUMN1_BACKGROUND" ]; then
        echo "default ($(get_color_name $column1_background))"
    else
        echo "$column1_background ($(get_color_name $column1_background))"
    fi

    echo -n "Column 1 font color = "
    if [ "$column1_font_color" -eq "$DEFAULT_COLUMN1_FONT_COLOR" ]; then
        echo "default ($(get_color_name $column1_font_color))"
    else
        echo "$column1_font_color ($(get_color_name $column1_font_color))"
    fi

    echo -n "Column 2 background = "
    if [ "$column2_background" -eq "$DEFAULT_COLUMN2_BACKGROUND" ]; then
        echo "default ($(get_color_name $column2_background))"
    else
        echo "$column2_background ($(get_color_name $column2_background))"
    fi

    echo -n "Column 2 font color = "
    if [ "$column2_font_color" -eq "$DEFAULT_COLUMN2_FONT_COLOR" ]; then
        echo "default ($(get_color_name $column2_font_color))"
    else
        echo "$column2_font_color ($(get_color_name $column2_font_color))"
    fi
}