#!/usr/bin/env bash
#
# Прогон упражнений ex00-ex10 на одной базе.
#
#   ./run.sh                    интерактивное меню, Enter — следующее упражнение
#   ./run.sh all                все одиннадцать подряд, без вопросов
#   DB_NAME=my_db ./run.sh all  прогон на другой базе
#
# ON_ERROR_STOP обязателен: без него psql печатает ошибку в запросе и всё равно
# завершается с нулевым кодом, поэтому сломанное упражнение в общем прогоне
# теряется. С ним ошибка возвращает ненулевой код и попадает в итоговый счётчик.
#
# Пути строятся от каталога скрипта, а не от текущего, — прогон работает
# из любого места.

set -uo pipefail

DB_NAME="${DB_NAME:-sqlb2_sets}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Названия из условий дня: меню без них показывает голые номера.
TITLES=(
  "UNION: объединение выборок"
  "UNION с подзапросом и сохранением дубликатов"
  "Уникальные значения без DISTINCT"
  "INTERSECT: пересечение журналов"
  "EXCEPT ALL: разность мультимножеств"
  "Декартово произведение"
  "Пересечение с расшифровкой имён"
  "Соединение через JOIN"
  "Тот же результат через NATURAL JOIN"
  "NOT IN против NOT EXISTS"
  "Соединение четырёх таблиц"
)
LAST=$(( ${#TITLES[@]} - 1 ))

if ! command -v psql > /dev/null; then
    echo "psql не найден. Нужен установленный клиент PostgreSQL." >&2
    exit 1
fi

if ! psql -d "$DB_NAME" -c '\q' 2> /dev/null; then
    echo "Не удалось подключиться к базе '$DB_NAME'." >&2
    echo "Создать и наполнить её схемой из поставки задания:" >&2
    echo "  createdb $DB_NAME && psql -d $DB_NAME -f model.sql" >&2
    exit 1
fi

run_exercise() {
    local n="$1" ex file
    ex=$(printf "ex%02d" "$n")
    file="$ROOT/$ex/day01_${ex}.sql"

    if [[ ! -f "$file" ]]; then
        echo "Файл не найден: $file" >&2
        return 1
    fi

    echo "── $ex — ${TITLES[$n]} ──"
    psql -d "$DB_NAME" -v ON_ERROR_STOP=1 -f "$file"
}

# Неинтерактивный режим: всё подряд, код возврата отражает результат прогона.
if [[ "${1:-}" == "all" ]]; then
    failed=0
    for i in $(seq 0 "$LAST"); do
        run_exercise "$i" || { echo "ОШИБКА в ex$(printf '%02d' "$i")" >&2; failed=$((failed + 1)); }
        echo "------------------------"
    done

    if (( failed > 0 )); then
        echo "Упражнений с ошибками: $failed" >&2
        exit 1
    fi
    echo "Все упражнения отработали."
    exit 0
fi

show_menu() {
    echo "Множества и соединения  (база: $DB_NAME)"
    echo
    for i in "${!TITLES[@]}"; do
        printf "  %2d  ex%02d  %s\n" "$i" "$i" "${TITLES[$i]}"
    done
    echo "   q  выход"
    echo
}

clear
show_menu
next=0

while true; do
    if (( next <= LAST )); then
        prompt=$(printf "Номер (0-%d), Enter = ex%02d, q — выход: " "$LAST" "$next")
    else
        prompt=$(printf "Все задания пройдены. Номер (0-%d) или q — выход: " "$LAST")
    fi

    read -rp "$prompt" input || break

    if [[ "$input" == "q" || "$input" == "Q" ]]; then
        break
    fi

    if [[ -z "$input" && $next -le $LAST ]]; then
        input="$next"
    fi

    if ! [[ "$input" =~ ^[0-9]+$ ]] || (( input > LAST )); then
        clear
        echo "Некорректный ввод: '$input' — нужно число 0-$LAST или q"
        echo
        show_menu
        continue
    fi

    clear
    run_exercise "$input"
    next=$(( input + 1 ))
    echo
done

clear
echo "Пока!"
