"""Предметная область экзамена: вопрос, студент, экзаменатор.

Объектная часть мультипарадигмального решения. Здесь нет ни ввода-вывода,
ни многопроцессности - только правила, описанные в задании.
"""

import random

# Золотое сечение. Условие задаёт веса формулами a=1/Ф, b=(1-a)/Ф, c=(1-a-b)/Ф,
# то есть рекуррентно: каждый следующий вес - это остаток, делённый на Ф.
# Поэтому в golden_weights цикл, а не выписанные формулы: так веса считаются
# для вопроса любой длины, и их сумма равна единице по построению.
PHI = (1 + 5 ** 0.5) / 2

MALE = 'М'
FEMALE = 'Ж'

QUEUED = 'Очередь'
PASSED = 'Сдал'
FAILED = 'Провалил'


def golden_weights(count):
    """Веса по закону золотого сечения.

    Первый вес равен 1/Ф, каждый следующий - оставшаяся доля, делённая на Ф,
    последний забирает весь остаток. Сумма весов всегда равна единице.

    :param count: Количество слов в вопросе.
    :return: Список весов от самого тяжёлого к самому лёгкому.
    """

    weights = []
    remaining = 1.0
    for _ in range(count - 1):
        weight = remaining / PHI
        weights.append(weight)
        remaining -= weight
    weights.append(remaining)
    return weights


class Question:
    """Вопрос из банка вопросов."""

    def __init__(self, text):
        self.text = text
        self.words = text.split()

    def weights_for(self, gender):
        """Веса слов для указанного пола.

        Мальчики вероятнее выбирают слова ближе к началу вопроса,
        девочки - ближе к концу.
        """

        weights = golden_weights(len(self.words))
        return weights if gender == MALE else weights[::-1]

    def answer(self, gender):
        """Наугад выбранное слово - ответ студента на этот вопрос."""

        return random.choices(self.words, weights=self.weights_for(gender))[0]

    def correct_answers(self, gender):
        """Слова, которые экзаменатор счёл верными ответами.

        Экзаменатор выбирает слово, затем с вероятностью 1/3 выбирает ещё одно,
        и так до тех пор, пока не остановится либо не переберёт все слова.
        """

        words = list(self.words)
        weights = self.weights_for(gender)
        chosen = set()
        while words:
            index = random.choices(range(len(words)), weights=weights)[0]
            chosen.add(words.pop(index))
            weights.pop(index)
            if random.random() >= 1 / 3:
                break
        return chosen

    def __str__(self):
        return self.text


class Person:
    """Участник экзамена: имя и пол."""

    def __init__(self, name, gender):
        self.name = name
        self.gender = gender

    @classmethod
    def parse(cls, line):
        """Создаёт участника из строки вида 'Степан М'."""

        name, gender = line.split()
        return cls(name, gender)

    def __str__(self):
        return self.name


class Student(Person):
    """Студент, пришедший сдавать экзамен."""


class Examiner(Person):
    """Экзаменатор, принимающий экзамен в отдельном процессе."""

    QUESTIONS = 3
    LUNCH_AFTER = 30.0
    LUNCH_RANGE = (12.0, 18.0)
    BAD_MOOD = 1 / 8
    GOOD_MOOD = 1 / 4

    def exam_duration(self):
        """Длительность экзамена зависит от длины имени экзаменатора."""

        length = len(self.name)
        return random.uniform(length - 1, length + 1)

    def lunch_duration(self):
        """Сколько экзаменатор не принимает студентов после обеда."""

        return random.uniform(*self.LUNCH_RANGE)

    def pick_questions(self, bank):
        """Три вопроса из банка. Повторы возможны только в маленьком банке."""

        if len(bank) >= self.QUESTIONS:
            return random.sample(bank, self.QUESTIONS)
        return random.choices(bank, k=self.QUESTIONS)

    def examine(self, student, bank):
        """Опрашивает студента и выносит решение.

        :return: Пара (сдал ли студент, тексты верно отвеченных вопросов).
        """

        correct = [
            question.text
            for question in self.pick_questions(bank)
            if question.answer(student.gender) in question.correct_answers(self.gender)
        ]
        return self.decide(len(correct)), correct

    def decide(self, correct_count):
        """Настроение экзаменатора решает судьбу студента."""

        mood = random.random()
        if mood < self.BAD_MOOD:
            return False
        if mood < self.BAD_MOOD + self.GOOD_MOOD:
            return True
        return correct_count > self.QUESTIONS - correct_count
