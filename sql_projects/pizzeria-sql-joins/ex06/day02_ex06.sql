-- Что заказывали Денис и Анна и в каких заведениях.
-- Заказ ссылается не на пиццерию, а на позицию меню, поэтому путь до названия
-- заведения идёт через menu: person_order → menu → pizzeria.
--
-- Сопоставлять заведение по имени пиццы было бы ошибкой: pizza_name не
-- уникален, одна и та же пицца есть в шести меню по разным ценам, и такой
-- запрос выдал бы все заведения, где она продаётся, вместо того одного,
-- где её действительно заказали.
SELECT m.pizza_name,
       pz.name AS pizzeria_name
FROM person_order po
         INNER JOIN person p ON po.person_id = p.id
         INNER JOIN menu m ON po.menu_id = m.id
         INNER JOIN pizzeria pz ON m.pizzeria_id = pz.id
WHERE p.name = 'Denis'
   OR p.name = 'Anna'
ORDER BY m.pizza_name, pizzeria_name;
