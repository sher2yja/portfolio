#!/bin/bash
# output.sh — вывод итоговой информации на экран и в лог

START_TIME="$1"
LOG_FILE="$2"
END_TIME=$(date +%s)

START_FMT=$(date -d @$START_TIME '+%Y-%m-%d %H:%M:%S')
END_FMT=$(date -d @$END_TIME '+%Y-%m-%d %H:%M:%S')
DURATION=$((END_TIME - START_TIME))

# Форматировать длительность в ЧЧ:ММ:СС
format_duration() {
  local T=$1
  printf "%02d:%02d:%02d" $((T/3600)) $((T%3600/60)) $((T%60))
}
DURATION_FMT=$(format_duration $DURATION)

INFO="Время старта: $START_FMT\nВремя окончания: $END_FMT\nОбщее время работы: $DURATION_FMT"

# Вывод на экран
echo -e "$INFO"
# Запись в лог
{
  echo -e "Итого:"
  echo -e "$INFO"
} >> "$LOG_FILE" 