#Задание 10. Аппараты
#Надо выбрать два аппарата одного года выпуска так, чтобы вместе они
#отработали ровно требуемое время, а суммарная стоимость была
#наименьшей. Ввод по условию надо проверять.

#Функция проверяет, что строка - натуральное число (1, 2, 3, ...)
def is_natural(text):
    return text.isdecimal() and int(text) > 0
    #isdecimal() истинно только для строки из обычных цифр 0-9: '-5' и
    #'abc' отсеются сразу. Похожий isdigit() пропустил бы надстрочные
    #знаки вроде ², на которых int() падает. Ноль проверяем отдельно -
    #натуральным он не считается


#Функция читает count строк с аппаратами и возвращает список троек.
#Если данные кривые - возвращает None вместо списка.
def read_devices(count):
    devices = []

    for _ in range(count):
        try:
            parts = input().split()     # режем строку на куски по пробелам
        except EOFError:
            return None             # строк меньше, чем обещала первая

        if len(parts) != 3:         # в строке должно быть ровно три числа
            return None             # None значит «данные плохие»

        if not all(is_natural(p) for p in parts):
            return None
        #all() истинно, только если is_natural дала True для КАЖДОГО куска

        year = int(parts[0])
        cost = int(parts[1])
        time = int(parts[2])

        devices.append((year, cost, time))  # кортеж - три числа разом

    return devices


#Функция ищет самую дешёвую подходящую пару аппаратов.
#Приём - полный перебор: аппаратов немного, поэтому просто пробуем
#все пары и запоминаем лучшую. Если пары нет, возвращает None.
def find_cheapest_pair(devices, required_time):
    best_cost = None                # лучшей пары пока не нашли

    for i in range(len(devices)):
        for j in range(i + 1, len(devices)):
            #j стартует с i+1, чтобы не брать один аппарат дважды и не
            #проверять одну и ту же пару второй раз в обратном порядке
            year1, cost1, time1 = devices[i]    # распаковка кортежа
            year2, cost2, time2 = devices[j]    # сразу по трём именам

            if year1 != year2:
                continue            # годы разные - пара не подходит

            if time1 + time2 != required_time:
                continue            # вместе работают не столько, сколько надо

            total_cost = cost1 + cost2

            if best_cost is None or total_cost < best_cost:
                best_cost = total_cost
            #первая найденная пара становится лучшей, дальше меняем
            #только если нашли дешевле. is None - проверка «ещё не задано»

    return best_cost


#Основная функция
def main():
    try:
        first_line = input().split()
    except EOFError:
        print('Invalid input')      # пустой поток - тоже некорректный ввод
        return

    if len(first_line) != 2 or not all(is_natural(p) for p in first_line):
        print('Invalid input')      # в первой строке ждём ровно два
        return                      # натуральных числа

    count = int(first_line[0])          # сколько аппаратов будет дальше
    required_time = int(first_line[1])  # сколько они должны отработать

    devices = read_devices(count)

    if devices is None:             # read_devices наткнулась на кривую строку
        print('Invalid input')
        return

    best_cost = find_cheapest_pair(devices, required_time)

    if best_cost is None:           # подходящей пары не нашлось
        print('No solution found')
    else:
        print(best_cost)


if __name__ == '__main__':
    main()