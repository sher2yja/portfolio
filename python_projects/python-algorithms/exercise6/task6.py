#Задание 6. Фильмы
#Два списка фильмов уже отсортированы по году. Надо слить их в один
#так, чтобы он тоже остался отсортированным, и вывести в формате json.
#Данные берём из файла input.txt, поэтому запускать надо из этой папки:
#cd exercise6 && python3 task6.py     (или ../run.py 6 из корня)
#Ввод проверяем: пустой файл - «Empty file», кривой - «Invalid input».

import json                 # разбирать json руками условие не требует,
                            # это единственный импорт во всём проекте


#Функция сливает два отсортированных списка в один отсортированный.
#Приём: идём по обоим спискам одновременно двумя указателями i и j
#и каждый раз забираем тот фильм, у которого год меньше.
#Заново сортировать не надо - внутри каждого списка порядок уже верный.
def merge_sorted(list1, list2):
    merged = []             # сюда складываем результат

    i = 0                   # указатель по первому списку
    j = 0                   # указатель по второму

    while i < len(list1) and j < len(list2):    # пока живы оба списка
        if list1[i]['year'] <= list2[j]['year']:
            merged.append(list1[i])     # год меньше у первого - берём его
            i += 1                      # и двигаем указатель первого
        else:
            merged.append(list2[j])     # иначе берём из второго
            j += 1

    merged.extend(list1[i:])    # один список кончился, у другого мог
    merged.extend(list2[j:])    # остаться хвост - дописываем его целиком
    #extend добавляет сразу все элементы, а append добавил бы весь
    #список одним элементом. Хвост уже отсортирован, и годы в нём
    #больше всех уже добавленных. Один из двух срезов всегда пустой

    return merged


#Функция проверяет, что данные и правда похожи на список фильмов.
#Возвращает True или False, ошибку не поднимает - решает уже main.
def is_valid_movie_list(movies):
    if not isinstance(movies, list):    # это вообще список?
        return False

    for movie in movies:
        if not isinstance(movie, dict): # каждый фильм должен быть словарём
            return False
        if 'title' not in movie or 'year' not in movie:
            return False                # оба поля обязаны быть на месте
        if not isinstance(movie['title'], str):
            return False                # название - строка
        if isinstance(movie['year'], bool):
            return False                # bool в Python это подвид int,
        #без этой строки {"year": true} пройдет
        if not isinstance(movie['year'], int):
            return False                # год - целое число
    #isinstance(что, тип) отвечает, нужного ли типа значение

    return True             # ни одна проверка не сорвалась - данные годные


#Основная функция
def main():
    with open('input.txt', 'r') as f:   # with сам закроет файл
        text = f.read()                 # читаем файл целиком в одну строку

    if text.strip() == '':      # в файле пусто или одни пробелы
        print('Empty file')     # текст задан условием дословно
        return

    try:
        data = json.loads(text)     # loads разбирает текст json в данные
    except json.JSONDecodeError:    # текст оказался не json
        print('Invalid input')
        return

    if not isinstance(data, dict):  # ждём объект {...}, а не список
        print('Invalid input')
        return
    if 'list1' not in data or 'list2' not in data:
        print('Invalid input')      # оба списка обязаны быть в файле
        return

    list1 = data['list1']
    list2 = data['list2']

    if not is_valid_movie_list(list1) or not is_valid_movie_list(list2):
        print('Invalid input')
        return

    merged = merge_sorted(list1, list2)

    print(json.dumps({'list0': merged}, indent=2))
    #dumps делает обратное loads: превращает данные в текст json.
    #indent=2 - отступ в два пробела, чтобы вывод читался.
    #Имя list0 и сам формат вывода заданы условием


if __name__ == '__main__':
    main()
