#!/bin/bash

# Часть 3. Проверка параметра и определение границ уборки.
#
# Корень берётся из первой строки журнала части 2 — там он записан как
# "ROOT<TAB>путь". Это и есть граница, за которую удаление не выходит ни
# в одном из трёх режимов.
#
# Если журнала нет, берётся песочница по умолчанию. Работать от корня
# файловой системы можно, но только явным указанием и с подтверждением:
#   ./main.sh 2 /

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/../02/log.txt"

if [ "$#" -lt 1 ]; then
  echo "Введите 1 параметр:"
  echo "1 — удаление по логу, 2 — удаление по дате, 3 — удаление по маске"
  echo "Необязательный второй параметр — корневой каталог уборки."
  exit 1
fi

CLEAN_MODE="$1"
if ! [[ "$CLEAN_MODE" =~ ^[123]$ ]]; then
  echo "Ошибка: параметр должен быть 1, 2 или 3."
  exit 1
fi

# Проверка существования лог-файла только для режима 1
if [ "$CLEAN_MODE" = "1" ] && [ ! -f "$LOG_FILE" ]; then
  echo "Ошибка: лог-файл не найден: $LOG_FILE"
  exit 1
fi

# Корень уборки: явный параметр → запись в журнале → песочница по умолчанию
if [ -n "$2" ]; then
  TARGET_ROOT="$2"
elif [ -f "$LOG_FILE" ]; then
  TARGET_ROOT=$(awk -F'\t' '$1=="ROOT" {print $2; exit}' "$LOG_FILE")
fi
TARGET_ROOT="${TARGET_ROOT:-$SCRIPT_DIR/../02/sandbox}"

if [ ! -d "$TARGET_ROOT" ]; then
  echo "Каталог уборки не существует: $TARGET_ROOT"
  echo "Похоже, убирать нечего."
  exit 0
fi
TARGET_ROOT="$(cd "$TARGET_ROOT" && pwd)"

if [ "$TARGET_ROOT" = "/" ]; then
  echo "ВНИМАНИЕ: уборка будет идти по всей файловой системе."
  echo "Под удаление могут попасть посторонние файлы, подходящие под условие."
  read -p "Продолжить? (введите YES заглавными): " CONFIRM
  if [ "$CONFIRM" != "YES" ]; then
    echo "Отменено."
    exit 1
  fi
fi

echo "Область уборки: $TARGET_ROOT"

export CLEAN_MODE
export LOG_FILE
export TARGET_ROOT
