#!/bin/bash

# Часть 5. Подсчёт объектов в каталоге.
#
# Все проходы делает find, разделяя объекты по типу: -type d каталоги,
# -type f файлы, -type l символические ссылки.
#
# Из числа каталогов вычитается единица — find включает в вывод сам
# каталог, с которого начат обход.
#
# Текстовые файлы считаются не по расширению, а по выводу file: расширение
# в Linux ничего не гарантирует. Это самая медленная проверка в скрипте —
# file запускается на каждый файл.
#
# Ошибки find подавляются через 2>/dev/null: при обходе системных каталогов
# часть подкаталогов закрыта на чтение, и это ожидаемо.

DIR_PATH="$1"

# 1. Общее число папок, включая вложенные
TOTAL_FOLDERS=$(find "$DIR_PATH" -type d 2>/dev/null | wc -l)
echo "Total number of folders (including all nested ones) = $((TOTAL_FOLDERS - 1))"

# 3. Общее число файлов
TOTAL_FILES=$(find "$DIR_PATH" -type f 2>/dev/null | wc -l)
echo "Total number of files = $TOTAL_FILES"

# 4. Число файлов разных типов
echo "Number of:"
CONF_FILES=$(find "$DIR_PATH" -type f -name "*.conf" 2>/dev/null | wc -l)
echo "Configuration files (with the .conf extension) = $CONF_FILES"

TEXT_FILES=$(find "$DIR_PATH" -type f -exec file {} \; 2>/dev/null | grep -c "text")
echo "Text files = $TEXT_FILES"

EXEC_FILES=$(find "$DIR_PATH" -type f -executable 2>/dev/null | wc -l)
echo "Executable files = $EXEC_FILES"

LOG_FILES=$(find "$DIR_PATH" -type f -name "*.log" 2>/dev/null | wc -l)
echo "Log files (with the extension .log) = $LOG_FILES"

ARCHIVE_FILES=$(find "$DIR_PATH" -type f \( -name "*.zip" -o -name "*.tar" -o -name "*.gz" -o -name "*.bz2" -o -name "*.rar" -o -name "*.7z" \) 2>/dev/null | wc -l)
echo "Archive files = $ARCHIVE_FILES"

SYMLINKS=$(find "$DIR_PATH" -type l 2>/dev/null | wc -l)
echo "Symbolic links = $SYMLINKS"