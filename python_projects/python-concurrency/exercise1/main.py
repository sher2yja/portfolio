"""Задание 2. Асинхронное скачивание изображений.

Пользователь вводит ссылки одну за другой, не дожидаясь загрузки предыдущей:
ввод живёт в отдельном потоке, а скачивания идут в цикле событий asyncio.
Ни одна ошибка не завершает программу - все они копятся до итоговой сводки.
"""

import asyncio
import os
from urllib.parse import unquote, urlparse

import aiohttp
from prettytable import PrettyTable

SUCCESS = 'Успех'
ERROR = 'Ошибка'
TIMEOUT = 30
PROBE = '.write-probe'


class Download:
    """Одна ссылка и судьба её загрузки."""

    def __init__(self, url):
        self.url = url
        self.status = None

    def succeed(self):
        self.status = SUCCESS

    def fail(self):
        self.status = ERROR

    @property
    def ok(self):
        return self.status == SUCCESS


def ask_directory():
    """Спрашивает путь до тех пор, пока по нему нельзя будет писать."""

    while True:
        path = input('Куда сохранять изображения: ').strip()
        if not path:
            print('Путь не может быть пустым.')
            continue
        try:
            os.makedirs(path, exist_ok=True)
            probe = os.path.join(path, PROBE)
            with open(probe, 'wb'):
                pass
            os.remove(probe)
        except OSError as error:
            print(f'Не подходит: {error.strerror or error}. Введи другой путь.')
            continue
        return path


def target_path(directory, url):
    """Свободное имя файла для изображения по ссылке."""

    name = os.path.basename(unquote(urlparse(url).path)) or 'image'
    stem, suffix = os.path.splitext(name)
    path = os.path.join(directory, name)
    number = 1
    while os.path.exists(path):
        path = os.path.join(directory, f'{stem}_{number}{suffix}')
        number += 1
    return path


async def download(session, record, directory):
    """Скачивает изображение и запоминает результат в record."""

    try:
        async with session.get(record.url) as response:
            if response.status != 200:
                record.fail()
                return
            content = await response.read()
        await asyncio.to_thread(save, target_path(directory, record.url), content)
    except (aiohttp.ClientError, asyncio.TimeoutError, OSError, ValueError,
            UnicodeError):
        record.fail()
    else:
        record.succeed()


def save(path, content):
    """Записывает изображение на диск побайтово."""

    with open(path, 'wb') as image:
        image.write(content)


async def read_urls(session, directory, records):
    """Читает ссылки и сразу отправляет каждую на скачивание."""

    tasks = []
    while True:
        try:
            # Обычный input() заблокировал бы цикл событий целиком, и толку
            # от асинхронности не было бы: следующую ссылку спросили бы только
            # после загрузки предыдущей. to_thread уводит ожидание ввода
            # в отдельный поток, и скачивания идут, пока пользователь печатает.
            url = await asyncio.to_thread(input, 'Ссылка (пустая строка - конец ввода): ')
        except EOFError:
            return tasks
        url = url.strip()
        if not url:
            return tasks
        record = Download(url)
        records.append(record)
        tasks.append(asyncio.create_task(download(session, record, directory)))


def summary(records):
    """Сводка об успешных и неуспешных загрузках."""

    table = PrettyTable(['Ссылка', 'Статус'])
    table.align['Ссылка'] = 'l'
    for record in records:
        table.add_row([record.url, record.status])
    return table


async def main():
    directory = await asyncio.to_thread(ask_directory)
    records = []
    timeout = aiohttp.ClientTimeout(total=TIMEOUT)
    async with aiohttp.ClientSession(timeout=timeout) as session:
        tasks = await read_urls(session, directory, records)
        pending = [task for task in tasks if not task.done()]
        if pending:
            print(f'Загрузка ещё идёт, осталось изображений: {len(pending)}. Жду...')
        await asyncio.gather(*tasks)
    if not records:
        print('Ни одной ссылки не введено.')
        return
    print(summary(records))
    print(f'Успешно: {sum(record.ok for record in records)} из {len(records)}')


if __name__ == '__main__':
    try:
        asyncio.run(main())
    except (EOFError, KeyboardInterrupt):
        print()
