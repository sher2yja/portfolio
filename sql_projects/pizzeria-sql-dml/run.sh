#!/usr/bin/env bash
#
# Прогон упражнений ex00-ex13.
#
#   ./run.sh 00        пересоздать базу и запустить ex00
#   ./run.sh 11        пересоздать базу, доиграть ex07..ex10, запустить ex11
#   ./run.sh -k 11     запустить ex11 на текущей базе, без пересоздания
#   ./run.sh all       пересоздать базу и прогнать ex00..ex13 по порядку
#   ./run.sh reset     только пересоздать базу из model.sql
#
#   DB=my_db ./run.sh all        другое имя базы
#   MODEL=/путь/model.sql ...    схема лежит не рядом со скриптом
#
# ПЕРЕСОЗДАНИЕ ЗДЕСЬ НЕ ПЕРЕСТРАХОВКА. Упражнения ex07-ex13 меняют данные
# и накапливаются: каждое написано в расчёте на то, что предыдущие уже
# применены. Запуск ex11 на базе, оставшейся от прошлого прогона, уронит
# вставку по дублю первичного ключа или second-раз уценит уже уценённую
# пиццу — и «неверный» результат будет виной базы, а не запроса.
#
# model.sql выдан курсом и в репозиторий не входит: без него выполнять
# запросы не на чем, поэтому скрипт сразу говорит, чего ему не хватает.
#
# ON_ERROR_STOP обязателен: без него psql печатает ошибку и всё равно
# завершается с нулевым кодом, и сломанное упражнение в общем прогоне теряется.

set -euo pipefail

DB="${DB:-sqlb4_dml}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODEL="${MODEL:-$ROOT/model.sql}"
LAST=13
FIRST_DML=7

TITLES=(
  "Цены для Кейт в диапазоне 800-1000"
  "Забытые позиции меню (без JOIN)"
  "Те же позиции с названиями и ценами"
  "Перевес визитов по полу: EXCEPT ALL"
  "Заказы только женщин и только мужчин: EXCEPT"
  "Заходил, но не заказывал"
  "Одна пицца по одной цене в разных пиццериях"
  "INSERT: новая пицца в меню"
  "INSERT без литеральных id"
  "INSERT нескольких строк: новые визиты"
  "INSERT: заказы на новую пиццу"
  "UPDATE: скидка 10%"
  "INSERT-SELECT с generate_series"
  "DELETE: откат акции"
)

for cmd in psql createdb dropdb; do
    if ! command -v "$cmd" > /dev/null; then
        echo "$cmd не найден. Нужен установленный клиент PostgreSQL." >&2
        exit 1
    fi
done

psql_run() { psql -v ON_ERROR_STOP=1 -d "$DB" "$@"; }

reset_db() {
    if [[ ! -f $MODEL ]]; then
        echo "Не найден файл схемы: $MODEL" >&2
        echo "Это model.sql из поставки задания, в репозитории его нет." >&2
        echo "Положи его рядом со скриптом или укажи путь: MODEL=/путь/model.sql" >&2
        exit 1
    fi
    dropdb --if-exists "$DB"
    createdb "$DB"
    psql_run -q -f "$MODEL"
    printf '== база %s пересоздана из %s\n' "$DB" "${MODEL##*/}"
}

run_one() {
    local n=$1 file="$ROOT/ex$1/day03_ex$1.sql"
    if [[ ! -f $file ]]; then
        printf 'нет файла %s\n' "$file" >&2
        return 1
    fi
    printf '\n== ex%s — %s\n' "$n" "${TITLES[10#$n]}"
    psql_run -f "$file"
}

usage() {
    awk 'NR > 2 && /^#/ { sub(/^# ?/, ""); print; next } NR > 2 { exit }' "${BASH_SOURCE[0]}"
    exit "${1:-0}"
}

keep=0
if [[ ${1:-} == -k || ${1:-} == --keep ]]; then
    keep=1
    shift
fi

case "${1:-}" in
    ''|-h|--help)
        usage
        ;;
    reset)
        reset_db
        ;;
    all)
        ((keep)) || reset_db
        for ((i = 0; i <= LAST; i++)); do
            run_one "$(printf '%02d' "$i")"
        done
        ;;
    *)
        arg=${1#ex}
        if ! [[ $arg =~ ^[0-9]{1,2}$ ]] || ((10#$arg > LAST)); then
            usage 1
        fi
        num=$((10#$arg))
        if ((!keep)); then
            reset_db
            # цепочка DML: доигрываем всё, что должно было отработать раньше
            for ((i = FIRST_DML; i < num; i++)); do
                run_one "$(printf '%02d' "$i")"
            done
        fi
        run_one "$(printf '%02d' "$num")"
        ;;
esac
