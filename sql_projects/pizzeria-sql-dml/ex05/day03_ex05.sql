-- Куда Андрей заходил, но ничего там не заказывал.
-- Задание существует ради главной особенности модели: журналы визитов
-- и заказов между собой не связаны, и «был, но не заказывал» — это не строка
-- в таблице, а разность двух множеств пиццерий.
--
-- Слева путь через person_visits, справа — через заказы: person_order → menu →
-- pizzeria, потому что заказ ссылается на позицию меню, а не на заведение.
SELECT pz.name AS pizzeria_name
FROM person_visits pv
         JOIN person p ON p.id = pv.person_id
         JOIN pizzeria pz ON pz.id = pv.pizzeria_id
WHERE p.name = 'Andrey'
EXCEPT
SELECT pz.name
FROM person_order po
         JOIN person p ON p.id = po.person_id
         JOIN menu m ON m.id = po.menu_id
         JOIN pizzeria pz ON pz.id = m.pizzeria_id
WHERE p.name = 'Andrey'
ORDER BY pizzeria_name;
