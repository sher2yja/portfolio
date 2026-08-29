#!/usr/bin/env python3
"""Запуск десяти задач проекта.

    ./run.py              меню: номер задачи - и она запускается
    ./run.py 3            запустить задачу 3 сразу, без меню

Файлу выданы права на исполнение, поэтому вызывается напрямую.
Если права слетят, работает и обычное python3 run.py ...

Скрипт лежит в корне проекта, а не внутри папок задач: условие требует,
чтобы в каталоге задачи не было ничего, кроме её собственных файлов.
"""

import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
# Папки задач лежат прямо рядом со скриптом
SRC = ROOT

TITLES = {
    1: 'Скалярное произведение',
    2: 'Палиндром',
    3: 'Фигуры',
    4: 'Треугольник Паскаля',
    5: 'Преобразование строки в число',
    6: 'Фильмы',
    7: 'Робот',
    8: 'Различные числа',
    9: 'Производная в точке',
    10: 'Аппараты',
}

# Задания 3 и 6 читают input.txt по относительному пути, поэтому запускать
# их надо из своей папки. Остальным это не мешает, так что заходим всегда.
READS_FILE = {3, 6}


def task_dir(number):
    return SRC / f'exercise{number}'


def cleanup():
    """Спека не любит лишние файлы, а python оставляет __pycache__."""
    for path in SRC.rglob('__pycache__'):
        shutil.rmtree(path, ignore_errors=True)


def show_list():
    print('Задания проекта:\n')
    for number, title in TITLES.items():
        mark = '  (читает input.txt)' if number in READS_FILE else ''
        print(f'  {number:>2}  {title}{mark}')
    print()


def launch(number):
    if number not in TITLES:
        print(f'Нет задания с номером {number}. Есть 1-10.')
        return 1

    # flush обязателен: наш print буферизуется, а запущенная программа
    # пишет в терминал напрямую - без сброса заголовок вылезет после вывода
    print(f'--- задание {number}. {TITLES[number]} ---', flush=True)
    if number in READS_FILE:
        print(f'(читает input.txt из {task_dir(number).relative_to(ROOT)})',
              flush=True)

    code = subprocess.run(
        [sys.executable, f'task{number}.py'], cwd=task_dir(number)
    ).returncode
    cleanup()
    return code


def menu():
    """Показывает список и запускает выбранное задание. И так по кругу."""
    while True:
        show_list()

        try:
            answer = input('Номер задания (Enter - выход): ').strip()
        except (EOFError, KeyboardInterrupt):
            # Ctrl+D или Ctrl+C на приглашении - тихо выходим
            print()
            return 0

        if answer == '' or answer.lower() in ('q', 'в', 'выход'):
            return 0

        if not answer.isdecimal():
            print(f'\nНужен номер от 1 до 10, а не {answer!r}.\n')
            continue

        print()
        launch(int(answer))

        try:
            input('\nEnter - вернуться к списку: ')
        except (EOFError, KeyboardInterrupt):
            print()
            return 0

        print()


def main():
    args = sys.argv[1:]

    if not args:
        # Меню имеет смысл только у живого терминала. Если ввод пришёл
        # из пайпа или файла, приглашение съело бы чужие данные.
        if sys.stdin.isatty():
            return menu()
        show_list()
        return 0

    if args[0].isdecimal():
        return launch(int(args[0]))

    print(f'Не понял аргумент {args[0]!r}.\n')
    show_list()
    return 1


if __name__ == '__main__':
    sys.exit(main())
