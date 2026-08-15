#!/bin/bash

# Часть 5. Рейтинги самых больших объектов каталога.
#
# Сортировка везде идёт через sort -hr — ключ -h понимает суффиксы K, M, G
# в выводе du и сравнивает размеры правильно, тогда как обычная сортировка
# поставила бы 9K выше 10M.
#
# В топе каталогов берутся строки со второй по шестую (head -6 | tail -5):
# первой строкой du печатает сам каталог обхода, а он в рейтинг не входит.
#
# find ... -exec du -h {} + запускает du пачками, а не по файлу на вызов, —
# на каталогах с тысячами файлов разница во времени существенная.

DIR_PATH="$1"

# 2. Топ-5 папок с самым большим весом
echo "TOP 5 folders of maximum size arranged in descending order (path and size):"
du -h "$DIR_PATH" 2>/dev/null | sort -hr | head -n 6 | tail -n 5 | awk '{print NR " - " $2 ", " $1}'

# 5. Топ-10 файлов с самым большим весом
echo "TOP 10 files of maximum size arranged in descending order (path, size and type):"
find "$DIR_PATH" -type f -exec du -h {} + 2>/dev/null | sort -hr | head -n 10 | awk '{print NR " - " $2 ", " $1}' | while read -r line; do
    file_path=$(echo "$line" | awk -F', ' '{print $1}' | cut -d' ' -f3-)
    size=$(echo "$line" | awk -F', ' '{print $2}')
    file_type=$(file -b "$file_path" | cut -d',' -f1)
    echo "${line%,*}, $file_type"
done | head -n 10

# 6. Топ-10 исполняемых файлов с самым большим весом
echo "TOP 10 executable files of the maximum size arranged in descending order (path, size and MD5 hash of file):"
find "$DIR_PATH" -type f -executable -exec du -h {} + 2>/dev/null | sort -hr | head -n 10 | awk '{print NR " - " $2 ", " $1}' | while read -r line; do
    file_path=$(echo "$line" | awk -F', ' '{print $1}' | cut -d' ' -f3-)
    size=$(echo "$line" | awk -F', ' '{print $2}')
    md5_hash=$(md5sum "$file_path" 2>/dev/null | awk '{print $1}')
    echo "${line%,*}, $md5_hash"
done | head -n 10