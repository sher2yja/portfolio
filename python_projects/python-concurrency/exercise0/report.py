"""Отчёты по экзамену: таблицы и итоговые строки.

Функциональная часть решения: все функции чистые и работают со снимком
состояния, а не с разделяемыми между процессами объектами.
"""

from prettytable import PrettyTable

from models import FAILED, PASSED, QUEUED


def _table(columns, rows, left):
    """Собирает таблицу, выравнивая по левому краю перечисленные столбцы."""

    table = PrettyTable(columns)
    for column in left:
        table.align[column] = 'l'
    for row in rows:
        table.add_row(row)
    return table


def _by_original_order(status, order, wanted):
    """Имена студентов с нужным статусом в порядке исходной очереди."""

    names = [name for name, value in status.items() if value == wanted]
    return sorted(names, key=order.get)


def live_students(snapshot, order):
    """Таблица студентов во время экзамена.

    Сначала те, кто ещё не услышал вердикт (в порядке сдачи),
    затем сдавшие, в конце - провалившие.
    """

    status = snapshot['status']
    # Студент, которого прямо сейчас опрашивают, показан со статусом «Очередь»
    # и учтён в счётчике оставшихся - так требует пример из условия. Статус
    # меняется в момент вердикта, а не в момент захода к экзаменатору.
    # Порядок внутри группы: сначала опрашиваемые, затем ждущие - именно
    # в этом порядке они закончат.
    rows = [(name, QUEUED) for name in snapshot['queued']]
    rows += [
        (name, wanted)
        for wanted in (PASSED, FAILED)
        for name in _by_original_order(status, order, wanted)
    ]
    return _table(['Студент', 'Статус'], rows, ['Студент'])


def final_students(snapshot, order):
    """Таблица студентов после экзамена: сначала сдавшие, затем провалившие."""

    status = snapshot['status']
    rows = [
        (name, wanted)
        for wanted in (PASSED, FAILED)
        for name in _by_original_order(status, order, wanted)
    ]
    return _table(['Студент', 'Статус'], rows, ['Студент'])


def work_time(state, now):
    """Время, реально потраченное экзаменатором на приём экзаменов.

    К уже накопленному времени добавляется незавершённый экзамен, поэтому
    счётчик растёт во время работы и замирает на обеде и после окончания.
    """

    _, _, _, busy, since = state
    return busy + (now - since if since is not None else 0.0)


def live_examiners(snapshot, now):
    """Таблица экзаменаторов во время экзамена."""

    rows = [
        (name, state[0] or '-', state[1], state[2], f'{work_time(state, now):.2f}')
        for name, state in snapshot['examiners'].items()
    ]
    return _table(
        ['Экзаменатор', 'Текущий студент', 'Всего студентов', 'Завалил', 'Время работы'],
        rows,
        ['Экзаменатор', 'Текущий студент'],
    )


def final_examiners(snapshot, now):
    """Таблица экзаменаторов после экзамена."""

    rows = [
        (name, state[1], state[2], f'{work_time(state, now):.2f}')
        for name, state in snapshot['examiners'].items()
    ]
    return _table(
        ['Экзаменатор', 'Всего студентов', 'Завалил', 'Время работы'],
        rows,
        ['Экзаменатор'],
    )


def _leaders(names, key, order):
    """Имена с минимальным значением key, в порядке исходной очереди."""

    if not names:
        return []
    best = min(map(key, names))
    return [name for name in sorted(names, key=order.get) if key(name) == best]


def best_students(snapshot, order):
    """Лучшие студенты - сдавшие экзамен быстрее остальных."""

    passed = [name for name, value in snapshot['status'].items() if value == PASSED]
    return _leaders(passed, snapshot['duration'].get, order)


def expelled_students(snapshot, order):
    """Отчисляют провалившихся, закончивших раньше других проваливших."""

    failed = [name for name, value in snapshot['status'].items() if value == FAILED]
    return _leaders(failed, snapshot['finished_at'].get, order)


def best_examiners(snapshot):
    """Лучшие экзаменаторы - с наименьшим процентом заваленных студентов."""

    working = {
        name: state[2] / state[1]
        for name, state in snapshot['examiners'].items()
        if state[1] > 0
    }
    if not working:
        return []
    best = min(working.values())
    return [name for name, rate in working.items() if rate == best]


def best_questions(snapshot):
    """Лучшие вопросы - те, на которые верно ответило больше всего студентов."""

    hits = snapshot['hits']
    best = max(hits.values(), default=0)
    if best == 0:
        return []
    return [text for text, count in hits.items() if count == best]


def _listing(names):
    return ', '.join(names) if names else '-'


def summary_lines(snapshot, order, total_time):
    """Итоговые строки отчёта - пункты 3-8 задания."""

    status = snapshot['status']
    passed = sum(1 for value in status.values() if value == PASSED)
    succeeded = status and passed / len(status) > 0.85
    return [
        f'Время с момента начала экзамена и до момента и его завершения: {total_time:.2f}',
        f'Имена лучших студентов: {_listing(best_students(snapshot, order))}',
        f'Имена лучших экзаменаторов: {_listing(best_examiners(snapshot))}',
        'Имена студентов, которых после экзамена отчислят: '
        f'{_listing(expelled_students(snapshot, order))}',
        f'Лучшие вопросы: {_listing(best_questions(snapshot))}',
        f'Вывод: экзамен {"удался" if succeeded else "не удался"}',
    ]
