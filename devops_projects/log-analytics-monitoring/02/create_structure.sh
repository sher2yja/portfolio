#!/bin/bash

# Часть 2. Создание папок и файлов в случайных местах внутри TARGET_ROOT.
#
# Каталоги-кандидаты ищутся find'ом на глубину 2 от TARGET_ROOT с исключением
# bin, sbin, media и /tmp: в системные каталоги писать нельзя, а /tmp
# очищается сам и для демонстрации нагрузки на диск не годится.
#
# Если внутри TARGET_ROOT подкаталогов ещё нет (обычный случай для чистой
# песочницы), кандидатом становится сам корень — иначе цикл не с чего начать.
#
# Свободное место проверяется ПЕРЕД каждым шагом, а не после: иначе цикл
# успел бы выйти за порог. Единица измерения разбирается явно — если df
# показывает уже не гигабайты, а мегабайты, работа прекращается сразу.
#
# Запятая в выводе df заменяется на точку: при русской локали дробная часть
# отделяется запятой, и bc такое число не примет.
#
# sudo здесь не используется намеренно. Скрипт создаёт объекты только там,
# где у запустившего пользователя и так есть право записи: это само по себе
# ограничивает возможный ущерб и не требует ввода пароля в цикле.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/generate_name.sh"
source "$SCRIPT_DIR/log.sh"

MAX_DIRS=100
MIN_NAME_LEN=5

# Получить список допустимых директорий для размещения (исключая системные)
get_valid_dirs() {
  {
    echo "$TARGET_ROOT"
    find "$TARGET_ROOT" -mindepth 1 -maxdepth 2 -type d 2>/dev/null
  } | grep -v -E "/(bin|sbin|media)(/|$)" \
    | grep -v "^/tmp" \
    | head -500
}

# Проверка свободного места (в гигабайтах)
get_free_space_gb() {
  # Получаем свободное место из df -h /
  local free_space=$(df -h / 2>/dev/null | awk 'NR==2 {print $4}')

  # Если не удалось получить данные, останавливаемся
  if [ -z "$free_space" ]; then
    echo "0"
    return
  fi

  # Заменяем запятую на точку для корректной обработки
  local free_space_clean=$(echo "$free_space" | sed 's/,/./g')

  # Извлекаем числовое значение и единицу измерения
  local value=$(echo "$free_space_clean" | sed 's/[A-Za-z]//g')
  local unit=$(echo "$free_space_clean" | sed 's/[0-9.]//g')

  # Проверяем единицу измерения
  case $unit in
    "G"|"T")
      # Если значение <= 1G, возвращаем 0 для остановки
      if (( $(echo "$value <= 1" | bc -l 2>/dev/null) )); then
        echo "0"
      else
        echo "$value"
      fi
      ;;
    "M"|"K"|*)
      # Если не гигабайты, останавливаемся (возвращаем 0)
      echo "0"
      ;;
  esac
}

# Основной цикл создания папок и файлов
count=0
while [ $count -lt $MAX_DIRS ]; do
  # Проверка свободного места перед каждым шагом
  free_gb=$(get_free_space_gb)
  if (( $(echo "$free_gb <= 1" | bc -l) )); then
    break
  fi

  # Выбираем случайную директорию для размещения папки
  valid_dirs=( $(get_valid_dirs) )
  if [ ${#valid_dirs[@]} -eq 0 ]; then
    break
  fi

  rand_idx=$((RANDOM % ${#valid_dirs[@]}))
  parent_dir="${valid_dirs[$rand_idx]}"

  # Сгенерировать имя папки
  folder_name=$(generate_name "$FOLDER_CHARS" $MIN_NAME_LEN)
  full_folder_path="$parent_dir/$folder_name"

  mkdir -p "$full_folder_path" 2>/dev/null
  if [ ! -d "$full_folder_path" ]; then
    # Нет прав на запись в этот каталог — берём следующий
    continue
  fi

  # Логируем создание папки
  log_object "$full_folder_path" "dir"

  # Внутренний цикл для создания файлов в текущей папке
  num_files=$(( (RANDOM % 5) + 1 ))
  for ((f=0; f<$num_files; f++)); do
    # Проверка свободного места перед созданием каждого файла
    free_gb=$(get_free_space_gb)
    if (( $(echo "$free_gb <= 1" | bc -l) )); then
      break 2  # Выходим из обоих циклов
    fi

    file_name=$(generate_name "$FILE_NAME_CHARS" $MIN_NAME_LEN "$FILE_EXT_CHARS")
    file_path="$full_folder_path/$file_name"

    # Создать файл нужного размера
    dd if=/dev/zero of="$file_path" bs=1M count=$FILE_SIZE_MB status=none 2>/dev/null
    if [ -f "$file_path" ]; then
      log_object "$file_path" "file"
    fi
  done

  count=$((count+1))
done
