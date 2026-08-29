-- Заказ greek pizza каждому клиенту — одним запросом.
-- Задание запрещает и отдельные INSERT, и оконные функции, поэтому номер строки
-- берётся у самого генератора ряда: generate_series(1, число людей) даёт
-- 1…9, и max(id) + gs.num назначает девять непересекающихся ключей.
--
-- Соединение идёт по равенству p.id = gs.num — это работает, пока
-- идентификаторы людей идут подряд от единицы. Появись в person пропуск,
-- часть клиентов молча осталась бы без заказа, а вставка прошла бы без ошибки.
-- Условие задания такой набор данных гарантирует, но в общем случае надёжнее
-- нумеровать саму выборку, а не полагаться на совпадение id с номером.
INSERT INTO person_order (id, person_id, menu_id, order_date)
SELECT (SELECT max(id) FROM person_order) + gs.num,
       p.id,
       (SELECT id FROM menu WHERE pizza_name = 'greek pizza'),
       '2022-02-25'
FROM generate_series(1, (SELECT count(*) FROM person)) AS gs(num)
         JOIN person p ON p.id = gs.num;
