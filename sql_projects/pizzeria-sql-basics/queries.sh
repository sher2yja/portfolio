#!/bin/bash
#
# Последовательный прогон всех упражнений ex00-ex09 на одной базе.
#
# Имя базы берётся из переменной окружения, значение по умолчанию совпадает
# с именем задания:
#   ./queries.sh                       прогон на sqlb1_basics
#   DB_NAME=my_db ./queries.sh         прогон на другой базе
#
# В сданной версии стояло sudo -u postgres psql: скрипт требовал root и
# выполнял запросы от суперпользователя базы. Здесь psql вызывается от
# текущего пользователя — для набора SELECT-ов повышенные права не нужны,
# а требовать sudo от того, кто просто хочет посмотреть запросы, незачем.
#
# Пути строятся от каталога скрипта, а не от текущего: прогон работает
# из любого места, а не только из корня проекта.

DB_NAME="${DB_NAME:-sqlb1_basics}"
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

failed=0

for i in {0..9}; do
    n=$(printf "%02d" "$i")
    file="$DIR/ex$n/day00_ex$n.sql"

    if [[ ! -f "$file" ]]; then
        echo "Файл не найден: $file" >&2
        failed=$((failed + 1))
        continue
    fi

    echo "Выполняю: ex$n"
    # ON_ERROR_STOP заставляет psql вернуть ненулевой код при ошибке в запросе.
    # Без него psql печатает сообщение и завершается успешно, и сломанный
    # запрос в общем прогоне остаётся незамеченным.
    if ! psql -d "$DB_NAME" -v ON_ERROR_STOP=1 -f "$file"; then
        echo "ОШИБКА в ex$n" >&2
        failed=$((failed + 1))
    fi
    echo "------------------------"
done

if [[ $failed -gt 0 ]]; then
    echo "Упражнений с ошибками: $failed" >&2
    exit 1
fi

echo "Все упражнения отработали."
