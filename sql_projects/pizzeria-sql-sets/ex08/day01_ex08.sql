-- То же самое, что в ex07, но через NATURAL JOIN.
-- Ловушка: у person_order и person обе таблицы имеют колонку id, но с разным
-- смыслом (id заказа vs id человека). "Голый" NATURAL JOIN соединил бы их по id —
-- неверно. Поэтому обе таблицы завёрнуты в подзапросы, где единственное общее
-- имя колонки — person_id: тогда NATURAL JOIN соединяет так же, как
-- ON p.id = po.person_id в ex07.
SELECT po.order_date, p.name || ' (age:' || p.age || ')' AS person_information
FROM (SELECT person_id, order_date FROM person_order) po
NATURAL JOIN (SELECT id AS person_id, name, age FROM person) p
ORDER BY po.order_date, person_information;
