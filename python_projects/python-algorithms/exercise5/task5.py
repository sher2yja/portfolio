#Задание 5. Преобразование строки в число
#Надо превратить строку в число и умножить его на 2, выведя результат
#с тремя знаками после точки. Функция float() и любые её аналоги
#условием запрещены, поэтому работаем со строкой посимвольно.
#Умножение делаем СТОЛБИКОМ, как на бумаге: справа налево, перенос
#уходит в старший разряд. Так вычисления идут в десятичной системе
#и погрешности двоичного представления не возникает вовсе.
#Ввод по условию надо проверять.

#Функция превращает один символ-цифру в число: '7' -> 7
def digit_value(ch):
    return ord(ch) - ord('0')
    #ord() выдаёт код символа в таблице символов. Коды цифр идут
    #подряд: '0' это 48, '1' это 49 ... '9' это 57. Значит разность
    #кодов и есть само число: 55 - 48 = 7


#Функция проверяет, что в строке только обычные цифры 0-9.
#Проверка строже, чем isdecimal(): digit_value умеет считать цифру
#только по коду ASCII, а знак вроде ² или цифра другой письменности
#дали бы не ошибку, а тихий мусор в результате.
def is_ascii_digits(text):
    return text.isdecimal() and text.isascii()


#Функция разбирает строку на знак, целую и дробную части.
#Ничего не считает - только проверяет и режет.
#Если строка не похожа на число, поднимает ValueError.
def parse_parts(text):
    text = text.strip()             # срезаем пробелы по краям

    sign = ''                       # знак храним строкой: '' или '-'
    if text.startswith('-'):
        sign = '-'
        text = text[1:]             # знак отрезали, дальше только цифры
    elif text.startswith('+'):
        text = text[1:]             # плюс просто отрезаем

    if text.count('.') > 1:         # '1.2.3' числом не является
        raise ValueError('больше одной точки')

    if '.' in text:
        int_part, frac_part = text.split('.')   # целая и дробная части
    else:
        int_part = text             # точки нет - вся строка целая часть
        frac_part = ''

    if int_part != '' and not is_ascii_digits(int_part):
        raise ValueError('в целой части не только цифры')
    if frac_part != '' and not is_ascii_digits(frac_part):
        raise ValueError('в дробной части не только цифры')
    #пустую часть пропускаем: '.5' и '5.' - допустимые записи числа

    if int_part == '' and frac_part == '':
        raise ValueError('нет ни одной цифры')
    #одна точка без единой цифры числом уже не является

    return sign, int_part, frac_part


#Функция умножает число на 2 столбиком и возвращает две пачки цифр:
#цифры целой части и цифры дробной. Точка при умножении на 2 никуда
#не сдвигается, поэтому её можно временно убрать: склеиваем цифры
#в одну ленту, считаем, а потом режем обратно по тому же месту.
def double_in_columns(int_part, frac_part):
    digits = [digit_value(c) for c in int_part + frac_part]

    carry = 0                       # перенос в старший разряд
    for k in range(len(digits) - 1, -1, -1):
        #range с шагом -1 идёт справа налево: от последней цифры к первой,
        #то есть от младшего разряда к старшему - как в столбике на бумаге
        doubled = digits[k] * 2 + carry
        digits[k] = doubled % 10    # остаток остаётся в этом разряде
        carry = doubled // 10       # целая часть деления уходит влево
        #при умножении на 2 перенос всегда 0 или 1: максимум 9*2+1 = 19

    int_length = len(int_part)      # где была точка

    if carry:                       # перенос вышел за старший разряд:
        digits.insert(0, carry)     # 5.0 -> 10.0, разрядов стало больше
        int_length += 1             # значит и точка сдвинулась вправо

    return digits[:int_length], digits[int_length:]


#Функция приводит дробную часть ровно к трём цифрам.
#Цифр меньше трёх - дописывает нули. Больше - округляет по четвёртой,
#и тогда перенос ползёт обратно ВЛЕВО и может перевалить через точку:
#0.9999 * 2 = 1.9998 -> 2.000
def round_to_three(int_digits, frac_digits):
    int_digits = list(int_digits)   # копии, чтобы не портить чужие списки
    frac_digits = list(frac_digits)

    if len(frac_digits) <= 3:
        while len(frac_digits) < 3:
            frac_digits.append(0)   # 14.5 -> 14.500
        return int_digits, frac_digits

    round_up = frac_digits[3] >= 5  # смотрим на первую отброшенную цифру
    frac_digits = frac_digits[:3]   # лишнее срезаем

    if not round_up:
        return int_digits, frac_digits

    for k in range(2, -1, -1):      # прибавляем 1 к последней цифре
        frac_digits[k] += 1
        if frac_digits[k] < 10:     # переноса нет - всё, готово
            return int_digits, frac_digits
        frac_digits[k] = 0          # было 9, стало 10: пишем 0,
        #а единицу переноса несём в следующий разряд слева

    for k in range(len(int_digits) - 1, -1, -1):
        int_digits[k] += 1          # перенос перевалил через точку
        if int_digits[k] < 10:
            return int_digits, frac_digits
        int_digits[k] = 0

    int_digits.insert(0, 1)         # 99.9999 -> 200.000, разряд прибавился
    return int_digits, frac_digits


#Функция собирает готовую строку для печати.
def build_text(sign, int_digits, frac_digits):
    while len(int_digits) > 1 and int_digits[0] == 0:
        int_digits = int_digits[1:] # '007' -> '14', ведущие нули не нужны
    #условие len > 1 бережёт единственный ноль: 0.5 должно остаться 0

    if not int_digits:
        int_digits = [0]            # ввод вида '.4' - целой части не было

    whole = ''.join(str(d) for d in int_digits)
    fraction = ''.join(str(d) for d in frac_digits)

    return sign + whole + '.' + fraction


#Основная функция
def main():
    try:
        text = input()
    except EOFError:
        print('Invalid input')
        return
    #Пустой поток - тоже некорректный ввод, а условие требует по нему
    #сообщение, а не трейсбек

    try:                            # try = «попробуй это выполнить»
        sign, int_part, frac_part = parse_parts(text)
    except ValueError:              # except ловит ошибку, если она была
        print('Invalid input')      # программа не падает с трейсбеком,
        return                      # а печатает сообщение и выходит

    int_digits, frac_digits = double_in_columns(int_part, frac_part)
    int_digits, frac_digits = round_to_three(int_digits, frac_digits)

    print(build_text(sign, int_digits, frac_digits))


if __name__ == '__main__':
    main()