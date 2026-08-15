#!/bin/bash

# Часть 6. Отчёт по логам через goaccess.
#
# goaccess строит из тех же логов части 4 готовую HTML-страницу со сводкой:
# посетители, коды ответов, популярные страницы.
#
# Пути считаются от расположения скрипта, а не от текущего каталога, — иначе
# запуск из другого места не находил бы логи.
#
# Отчёт по умолчанию кладётся рядом со скриптом. При работе на виртуальной
# машине его удобно сразу писать в общую папку VirtualBox, чтобы открыть
# браузером на хосте, — для этого путь задаётся переменной окружения:
#
#   REPORT_PATH=/media/sf_shared/report.html ./main.sh
#
# Раньше этот путь был вписан в скрипт жёстко, и на машине без такой общей
# папки goaccess завершался ошибкой перенаправления.

if [ $# != 0 ]; then
  echo -e "\e[91mCкрипт должен запускаться без параметров.\e[0m"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$SCRIPT_DIR/../04"
REPORT_PATH="${REPORT_PATH:-$SCRIPT_DIR/report.html}"

if ! command -v goaccess >/dev/null 2>&1; then
  echo -e "\e[91mgoaccess не установлен: sudo apt install goaccess\e[0m"
  exit 1
fi

LOG_FILES=("$LOG_DIR"/*.log)
if [ ! -e "${LOG_FILES[0]}" ]; then
  echo -e "\e[91mЛоги не найдены в $LOG_DIR — сначала запустите часть 4.\e[0m"
  exit 1
fi

# Каталог назначения может не существовать, если путь задан переменной
mkdir -p "$(dirname "$REPORT_PATH")" 2>/dev/null

goaccess "${LOG_FILES[@]}" --log-format=COMBINED > "$REPORT_PATH"
echo "Отчёт сохранён: $REPORT_PATH"
