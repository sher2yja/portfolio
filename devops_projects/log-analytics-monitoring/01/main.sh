#!/bin/bash

# Часть 1. Создание структуры папок и файлов в заданном каталоге.
#
# Скрипт нагрузочный: создаёт folders_num папок, в каждой files_num файлов
# заданного размера. Останавливается сам, когда на разделе остаётся 1 ГБ, —
# проверка memcheck вызывается перед созданием каждого файла.
#
# Имена генерируются детерминированно из набора букв: generate_name по индексу
# строит уникальную комбинацию, повторяя одну из букв. Так имена не
# конфликтуют и при этом не требуют счётчика коллизий.
#
# Все имена получают суффикс с датой создания — по нему часть 3 находит,
# что удалять.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/validation.sh"

# Генерация массива уникальных символов
function create_arr() {
  arr_name=$1
  n=0
  for (( i = 0; i < ${#arr_name}; ++i)); do
    if ! [ "${arr_name:$i:1}" == "${arr_name:$(($i+1)):1}" ]; then
      simb_array[$n]="${arr_name:$i:1}"
      n=$(($n+1))
    fi
  done
  echo "${simb_array[@]}"
}

# Генерация имени папки/файла
function generate_name() {
  idx=$1
  chars_in_name=$2
  simbs_array=($(create_arr $chars_in_name))
  index_arr=$(($idx%${#chars_in_name}))
  repetition=$(($idx/${#chars_in_name}))
  new_name=""
  for (( j = 0; j < ${#chars_in_name}; j++ )); do
    simb=${simbs_array[j]}
    new_name=${new_name}${simb}
    if [ "$j" -eq "$index_arr" ]; then
      for ((k = 0; k <= ${repetition}; k++)); do
        new_name="${new_name}${simb}"
      done
    fi
  done
  echo "$new_name"
}

# Проверка свободного места (остановка, если <= 1ГБ)
function memcheck() {
  avail=$(df -P -BG "$dir" | tail -1 | awk '{print $4}' | sed 's/G//')
  if [ "$avail" -le 1 ]; then
    echo 1
  else
    echo 0
  fi
}

# Создание папок и файлов
function create_folders() {
  i=$1
  LOG_FILE=$2
  new_fo=$(generate_name $i $folders_names)_$(date +"%d%m%y")
  mkdir -p "$dir/$new_fo"
  echo "PATH: $dir/$new_fo, DATE: $(date +"%d.%m.%Y %H:%M:%S"), NAME: $new_fo" >> "$LOG_FILE"
  for (( k = 0; k < $files_num; k++ )); do
    if [ $(memcheck) -eq 1 ]; then
      exit 1
    fi
    new_fi=$(generate_name $k ${array_fi[0]})_$(date +"%d%m%y").${array_fi[1]} 
    touch "$dir/$new_fo/$new_fi"
    truncate -s ${file_size_num}K "$dir/$new_fo/$new_fi"
    fsize=$(stat -c%s "$dir/$new_fo/$new_fi")
    echo "PATH: $dir/$new_fo/$new_fi, DATE: $(date +"%d.%m.%Y %H:%M:%S"), NAME: $new_fi, SIZE: $fsize bytes" >> "$LOG_FILE"
  done
}

# Основная логика
LOG_FILE="$dir/report.log"
rm -f "$LOG_FILE"
touch "$LOG_FILE"

# Создание папок
for ((i = 0; i < folders_num; i++)); do
  create_folders $i "$LOG_FILE"
done 