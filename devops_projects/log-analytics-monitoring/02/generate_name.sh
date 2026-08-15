#!/bin/bash
# generate_name.sh — генерация имен папок и файлов по правилам

# Функция генерации имени (папки или файла)
# $1 — строка букв (например, az)
# $2 — минимальная длина (например, 5)
# $3 — расширение (опционально)
generate_name() {
  local chars="$1"
  local minlen="$2"
  local ext="$3"
  local name=""
  local used_chars=""
  local charslen=${#chars}
  
  # Пока не использовали все буквы или не достигли минимальной длины
  while [ ${#used_chars} -lt $charslen ] || [ ${#name} -lt $minlen ]; do
    # Если еще не использовали все буквы
    if [ ${#used_chars} -lt $charslen ]; then
      # Находим первую неиспользованную букву
      for ((i=0; i<charslen; i++)); do
        local current_char="${chars:$i:1}"
        if [[ ! "$used_chars" =~ "$current_char" ]]; then
          # Добавляем текущую букву
          name+="$current_char"
          used_chars+="$current_char"
          
          # Случайно решаем, переходить ли к следующей букве
          if [ $((RANDOM % 2)) -eq 1 ]; then
            # Переходим к следующей букве (уже добавлена выше)
            break
          else
            # Остаемся на текущей букве, добавим ее еще раз
            name+="$current_char"
          fi
          break
        fi
      done
    else
      # Все буквы использованы, но длина меньше минимальной
      # Добавляем случайные буквы из уже использованных
      local random_char="${chars:$((RANDOM % charslen)):1}"
      name+="$random_char"
    fi
  done

  # Добавляем дату в формате DDMMYY
  local datepart=$(date +%d%m%y)
  local final_name="${name}_$datepart"

  # Если есть расширение — добавляем
  if [ -n "$ext" ]; then
    final_name+=".$ext"
  fi

  echo "$final_name"
}

# Пример использования:
# generate_name "$FOLDER_CHARS" 5
# generate_name "$FILE_NAME_CHARS" 5 "$FILE_EXT_CHARS" 