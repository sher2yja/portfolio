-- Цепочка из трёх внешних ключей, чтобы дойти от заказа до имени пиццерии:
-- person_order -> person (кто заказал), person_order -> menu (что заказал),
-- menu -> pizzeria (в какой пиццерии). Каждый JOIN — ещё один "прыжок" по FK.
SELECT p.name AS person_name, m.pizza_name, pz.name AS pizzeria_name
FROM person_order po
JOIN person p ON p.id = po.person_id
JOIN menu m ON m.id = po.menu_id
JOIN pizzeria pz ON pz.id = m.pizzeria_id
ORDER BY person_name, pizza_name, pizzeria_name;
