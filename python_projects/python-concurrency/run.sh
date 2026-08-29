#!/usr/bin/env bash
# Запуск обеих программ проекта.
# Системный Python защищён PEP 668, поэтому зависимости ставим в локальный .venv.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV="$ROOT/.venv"
PYTHON="$VENV/bin/python3"
EXAM_DIR="$ROOT/exercise0"
IMAGES_DIR="$ROOT/exercise1"

ensure_venv() {
    if [ ! -x "$PYTHON" ]; then
        echo "Создаю виртуальное окружение в .venv ..."
        python3 -m venv "$VENV"
    fi
    if ! "$PYTHON" -c 'import aiohttp, prettytable' 2>/dev/null; then
        echo "Устанавливаю зависимости из requirements.txt ..."
        "$PYTHON" -m pip install --quiet --upgrade pip
        "$PYTHON" -m pip install --quiet -r "$ROOT/requirements.txt"
    fi
}

run_exam() {
    ensure_venv
    (cd "$EXAM_DIR" && "$PYTHON" main.py)
}

run_images() {
    ensure_venv
    (cd "$IMAGES_DIR" && "$PYTHON" main.py)
}

run_check() {
    ensure_venv
    echo "Проверяю синтаксис ..."
    "$PYTHON" -m py_compile "$EXAM_DIR"/*.py "$IMAGES_DIR"/*.py
    bash -n "$ROOT/run.sh"
    echo "Синтаксис в порядке."
}

usage() {
    cat <<'USAGE'
Использование: ./run.sh [команда]

  1, exam     Программа 1 - моделирование экзамена
  2, images   Программа 2 - асинхронное скачивание изображений
  check       Проверка синтаксиса всех файлов
  help        Эта справка

Без аргументов выводится меню.
USAGE
}

menu() {
    echo "Параллельность в Python"
    echo "  1) Экзамен на процессах"
    echo "  2) Асинхронное скачивание изображений"
    echo "  3) Проверка синтаксиса"
    echo "  0) Выход"
    read -r -p "Выбери пункт: " choice
    case "$choice" in
        1) run_exam ;;
        2) run_images ;;
        3) run_check ;;
        0) ;;
        *) echo "Нет такого пункта." >&2; exit 1 ;;
    esac
}

case "${1:-}" in
    1|exam) run_exam ;;
    2|images) run_images ;;
    check) run_check ;;
    help|-h|--help) usage ;;
    "") menu ;;
    *) echo "Неизвестная команда: $1" >&2; usage >&2; exit 1 ;;
esac
