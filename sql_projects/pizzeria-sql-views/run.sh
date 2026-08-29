#!/usr/bin/env bash
#
# Прогон упражнений ex00-ex08.
#
#   ./run.sh reset     подготовить базу
#   ./run.sh all       подготовить базу и выполнить ex00..ex08 по порядку
#   ./run.sh ex05      выполнить одно упражнение на текущей базе
#   ./run.sh check     сквозной прогон на временной базе со сверкой результатов
#   ./run.sh psql      интерактивная сессия к базе
#
#   DB=имя             имя рабочей базы (по умолчанию sqlb5_views)
#   MODEL=/путь/model.sql   схема из поставки задания, в репозитории её нет
#   DML=/путь/к/pizzeria-sql-dml   откуда взять DML-скрипты (по умолчанию рядом)
#   BASE=имя           взять готовую базу копией вместо сборки из схемы
#
# СТАРТОВОЕ СОСТОЯНИЕ БАЗЫ ЗДЕСЬ НЕ ПРОИЗВОЛЬНО. Условие требует, чтобы
# изменения из соседнего проекта про DML оставались на месте: две записи
# в журналах, одна позиция меню и удалённая «greek pizza». Поэтому база
# собирается из схемы, а поверх неё проигрываются ex07..ex13 того проекта —
# то есть требуемое состояние воспроизводится из самого репозитория,
# а не берётся откуда-то извне. Готовую базу можно передать через BASE=.

set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DB="${DB:-sqlb5_views}"
MODEL="${MODEL:-$ROOT/model.sql}"
DML="${DML:-$ROOT/../pizzeria-sql-dml}"
BASE="${BASE:-}"
EXERCISES=(ex00 ex01 ex02 ex03 ex04 ex05 ex06 ex07 ex08)
DML_CHAIN=(07 08 09 10 11 12 13)
FAILED=0

die() { printf 'ошибка: %s\n' "$*" >&2; exit 1; }

usage() {
    awk 'NR > 2 && /^#/ { sub(/^# ?/, ""); print; next } NR > 2 { exit }' "${BASH_SOURCE[0]}"
}

for cmd in psql createdb dropdb; do
    command -v "$cmd" > /dev/null || die "$cmd не найден, нужен клиент PostgreSQL"
done

script_for() { printf '%s/%s/day04_%s.sql' "$ROOT" "$1" "$1"; }
db_exists() { psql -lqtA -F'|' | cut -d'|' -f1 | grep -qx "$1"; }
val() { psql -v ON_ERROR_STOP=1 -tA -d "$DB" -c "$1"; }
out() { psql -v ON_ERROR_STOP=1 -tA -q -d "$DB" -f "$(script_for "$1")"; }

prepare_db() {
    dropdb --if-exists "$DB" 2> /dev/null
    if [ -n "$BASE" ]; then
        db_exists "$BASE" || die "нет базы-источника '$BASE'"
        createdb -T "$BASE" "$DB"
        printf "база '%s' создана копией '%s'\n" "$DB" "$BASE"
        return
    fi
    [ -f "$MODEL" ] || die "не найден файл схемы: $MODEL
Это model.sql из поставки задания, в репозитории его нет.
Положи его рядом со скриптом или укажи путь: MODEL=/путь/model.sql"
    createdb "$DB"
    psql -v ON_ERROR_STOP=1 -q -d "$DB" -f "$MODEL"
    printf "база '%s' создана из %s\n" "$DB" "${MODEL##*/}"

    # Требуемое стартовое состояние = схема + изменения из проекта про DML.
    local n f applied=0
    for n in "${DML_CHAIN[@]}"; do
        f="$DML/ex$n/day03_ex$n.sql"
        [ -f "$f" ] || break
        psql -v ON_ERROR_STOP=1 -q -d "$DB" -f "$f"
        applied=$((applied + 1))
    done
    if [ "$applied" -eq "${#DML_CHAIN[@]}" ]; then
        printf "поверх неё проиграны ex07..ex13 из %s\n" "${DML##*/}"
    else
        printf 'ВНИМАНИЕ: скрипты DML не найдены в %s\n' "$DML" >&2
        printf 'Стартовое состояние неполное: в v_price_with_discount будет 20 строк вместо 22.\n' >&2
    fi
}

cmd_one() {
    local f
    f="$(script_for "$1")"
    [ -f "$f" ] || die "нет файла $f"
    db_exists "$DB" || die "нет базы '$DB' — сначала ./run.sh reset"
    printf '\n=== %s ===\n' "$1"
    psql -v ON_ERROR_STOP=1 -d "$DB" -f "$f"
}

cmd_all() {
    prepare_db
    local ex
    for ex in "${EXERCISES[@]}"; do
        cmd_one "$ex"
    done
}

# assert <описание> <ожидание> <факт>
assert() {
    if [ "$2" = "$3" ]; then
        printf '    ok    %s\n' "$1"
    else
        printf '    FAIL  %s: ожидалось «%s», получено «%s»\n' "$1" "$2" "$3"
        FAILED=1
    fi
}

step() {
    printf '  %s\n' "$1"
    psql -v ON_ERROR_STOP=1 -q -d "$DB" -f "$(script_for "$1")" > /dev/null
}

lines() { printf '%s\n' "$1" | wc -l | tr -d ' '; }

cmd_check() {
    DB="${DB}_check"
    prepare_db
    # shellcheck disable=SC2064  # $DB нужно развернуть сейчас, а не при выходе
    trap "dropdb --if-exists '$DB' 2> /dev/null || true" EXIT

    printf 'Сквозной прогон на временной базе %s\n' "$DB"
    local r

    step ex00
    assert "ex00: 5 женщин / 4 мужчин" "5|4" \
        "$(val "select (select count(*) from v_persons_female)||'|'||(select count(*) from v_persons_male)")"

    printf '  ex01\n'
    r=$(out ex01)
    assert "ex01: 9 имён"      "9"      "$(lines "$r")"
    assert "ex01: сортировка"  "Andrey" "$(printf '%s\n' "$r" | head -1)"

    step ex02
    assert "ex02: 31 дата"  "31"   "$(val 'select count(*) from v_generated_dates')"
    assert "ex02: тип DATE" "date" "$(val 'select pg_typeof(generated_date)::text from v_generated_dates limit 1')"

    printf '  ex03\n'
    r=$(out ex03)
    assert "ex03: 21 пропущенный день" "21"         "$(lines "$r")"
    assert "ex03: первый день"         "2022-01-11" "$(printf '%s\n' "$r" | head -1)"

    step ex04
    assert "ex04: (R-S) U (S-R)" "2,8" \
        "$(val "select string_agg(person_id::text, ',' order by person_id) from v_symmetric_union")"

    step ex05
    assert "ex05: Andrey / cheese pizza" "800|720" \
        "$(val "select price||'|'||discount_price from v_price_with_discount where name='Andrey' and pizza_name='cheese pizza'")"

    step ex06
    assert "ex06: снимок до обновления" "Papa Johns" \
        "$(val "select string_agg(name, ',' order by name) from mv_dmitriy_visits_and_eats")"

    step ex07
    assert "ex07: снимок после REFRESH" "DoDo Pizza,Papa Johns" \
        "$(val "select string_agg(name, ',' order by name) from mv_dmitriy_visits_and_eats")"

    step ex08
    assert "ex08: представлений не осталось" "0" \
        "$(val "select count(*) from pg_class where relkind in ('v','m') and relnamespace='public'::regnamespace")"
    assert "ex08: пять таблиц целы" "5" \
        "$(val "select count(*) from pg_class where relkind='r' and relnamespace='public'::regnamespace")"

    printf -- '-----\n'
    if [ "$FAILED" -eq 0 ]; then
        echo "Все проверки пройдены"
    else
        echo "Есть расхождения"
        exit 1
    fi
}

case "${1:-}" in
    reset)          prepare_db ;;
    all)            cmd_all ;;
    check)          cmd_check ;;
    psql)           exec psql -d "$DB" ;;
    ex0[0-8])       cmd_one "$1" ;;
    -h|--help|'')   usage ;;
    *)              die "неизвестная команда: $1" ;;
esac
