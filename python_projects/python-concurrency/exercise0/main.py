"""Задание 1. Моделирование экзамена.

Каждый экзаменатор принимает экзамен в отдельном процессе, студенты стоят
в одной общей очереди. Главный процесс ничего не считает - он только
показывает состояние экзамена и обновляет его на месте.
"""

import os
import time
from multiprocessing import Manager, Process

import report
from models import Examiner, FAILED, PASSED, QUEUED, Question, Student

EXAMINERS_FILE = 'examiners.txt'
STUDENTS_FILE = 'students.txt'
QUESTIONS_FILE = 'questions.txt'
REFRESH = 0.25


def read_lines(path):
    """Непустые строки файла без завершающих пробелов."""

    with open(path, 'r', encoding='utf-8') as source:
        return [line.strip() for line in source if line.strip()]


def load(path, factory):
    """Читает файл и превращает каждую строку в объект."""

    return list(map(factory, read_lines(path)))


def clear_screen():
    os.system('cls' if os.name == 'nt' else 'clear')


class ExamState:
    """Состояние экзамена, разделяемое между процессами экзаменаторов.

    Все изменения идут под общим замком, поэтому очередь и статистика
    остаются согласованными, а главный процесс всегда снимает целостный срез.
    """

    def __init__(self, manager, students, examiners, questions):
        self.lock = manager.Lock()
        # Аргументы manager.list и manager.dict пиклятся и уходят в процесс
        # менеджера, а генераторное выражение не пиклится. Отсюда квадратные
        # и фигурные скобки: передаём готовый список и готовый словарь,
        # иначе TypeError: cannot pickle 'generator' object.
        self.queue = manager.list([student.name for student in students])
        self.current = manager.list()
        self.status = manager.dict({student.name: QUEUED for student in students})
        self.finished_at = manager.dict()
        self.duration = manager.dict()
        self.examiners = manager.dict(
            {examiner.name: (None, 0, 0, 0.0, None) for examiner in examiners}
        )
        self.hits = manager.dict({question.text: 0 for question in questions})
        self.order = {student.name: index for index, student in enumerate(students)}

    def take_next(self, examiner_name, now):
        """Берёт следующего студента из очереди. None - очередь пуста."""

        with self.lock:
            if not self.queue:
                return None
            name = self.queue.pop(0)
            self.current.append(name)
            # Состояние экзаменатора переприсваивается целым кортежем.
            # Правка вложенной структуры на месте (state[0] = name) изменила бы
            # локальную копию в этом процессе, а до менеджера не дошла бы.
            state = self.examiners[examiner_name]
            self.examiners[examiner_name] = (name, state[1], state[2], state[3], now)
            return name

    def finish(self, examiner_name, student, passed, correct, duration, elapsed):
        """Записывает вердикт по студенту и обновляет статистику."""

        with self.lock:
            self.current.remove(student)
            self.status[student] = PASSED if passed else FAILED
            self.finished_at[student] = elapsed
            self.duration[student] = duration
            for text in correct:
                self.hits[text] = self.hits[text] + 1
            state = self.examiners[examiner_name]
            self.examiners[examiner_name] = (
                None,
                state[1] + 1,
                state[2] + (0 if passed else 1),
                state[3] + duration,
                None,
            )

    def snapshot(self):
        """Целостный срез состояния в виде обычных структур Python."""

        with self.lock:
            return {
                'queued': list(self.current) + list(self.queue),
                'status': dict(self.status),
                'finished_at': dict(self.finished_at),
                'duration': dict(self.duration),
                'examiners': dict(self.examiners),
                'hits': dict(self.hits),
            }


def run_examiner(examiner, students, questions, state, started_at):
    """Рабочий цикл одного экзаменатора - выполняется в отдельном процессе."""

    had_lunch = False
    while True:
        name = state.take_next(examiner.name, time.monotonic())
        if name is None:
            break
        duration = examiner.exam_duration()
        passed, correct = examiner.examine(students[name], questions)
        time.sleep(duration)
        state.finish(
            examiner.name, name, passed, correct, duration,
            time.monotonic() - started_at,
        )
        if not had_lunch and time.monotonic() - started_at >= Examiner.LUNCH_AFTER:
            had_lunch = True
            time.sleep(examiner.lunch_duration())


def show_progress(state, started_at):
    """Показывает текущее состояние экзамена вместо предыдущего."""

    now = time.monotonic()
    snapshot = state.snapshot()
    status = snapshot['status']
    left = sum(1 for value in status.values() if value == QUEUED)
    clear_screen()
    print(report.live_students(snapshot, state.order))
    print()
    print(report.live_examiners(snapshot, now))
    print()
    print(f'Осталось в очереди: {left} из {len(status)}')
    print(f'Время с момента начала экзамена: {now - started_at:.2f}')


def show_results(state, started_at, finished_at):
    """Выводит итоги экзамена вместо промежуточной информации."""

    snapshot = state.snapshot()
    clear_screen()
    print(report.final_students(snapshot, state.order))
    print()
    print(report.final_examiners(snapshot, finished_at))
    print()
    for line in report.summary_lines(snapshot, state.order, finished_at - started_at):
        print(line)


def main():
    students = load(STUDENTS_FILE, Student.parse)
    examiners = load(EXAMINERS_FILE, Examiner.parse)
    questions = load(QUESTIONS_FILE, Question)
    if not students or not examiners or not questions:
        print('Нужны непустые списки студентов, экзаменаторов и вопросов.')
        return

    with Manager() as manager:
        state = ExamState(manager, students, examiners, questions)
        by_name = {student.name: student for student in students}
        started_at = time.monotonic()
        processes = [
            Process(
                target=run_examiner,
                args=(examiner, by_name, questions, state, started_at),
            )
            for examiner in examiners
        ]
        for process in processes:
            process.start()
        while any(process.is_alive() for process in processes):
            show_progress(state, started_at)
            time.sleep(REFRESH)
        for process in processes:
            process.join()
        show_results(state, started_at, time.monotonic())


if __name__ == '__main__':
    main()
