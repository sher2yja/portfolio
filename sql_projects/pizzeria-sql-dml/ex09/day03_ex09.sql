-- Два визита сразу: Денис и Ирина в Dominos 24 февраля.
-- Строк вставляется больше одной, а ключ у каждой должен быть свой — отсюда
-- row_number(): он нумерует строки выборки, и максимум таблицы плюс этот номер
-- даёт 20 и 21. Оконные функции здесь разрешены, запрещены они только в ex12.
--
-- Имена в WHERE, а не идентификаторы: прямые числа для ключей и ссылки
-- на пиццерию в этом задании запрещены.
INSERT INTO person_visits (id, person_id, pizzeria_id, visit_date)
SELECT (SELECT max(id) FROM person_visits) + row_number() OVER (ORDER BY p.id),
       p.id,
       (SELECT id FROM pizzeria WHERE name = 'Dominos'),
       '2022-02-24'
FROM person p
WHERE p.name IN ('Denis', 'Irina');
