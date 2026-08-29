-- Мужчины из Москвы или Самары, заказывавшие пепперони или грибную пиццу.
-- Условия на пиццу и на человека лежат в разных таблицах, но проверяются на
-- одной и той же строке результата — «или/или» внутри каждой пары скобок,
-- «и» между ними.
--
-- DISTINCT обязателен: у человека может быть несколько подходящих заказов,
-- и без него имя вернулось бы столько раз, сколько их нашлось. Сортировка
-- по убыванию — требование задания.
SELECT DISTINCT p.name
FROM person p
         INNER JOIN person_order po ON p.id = po.person_id
         INNER JOIN menu m ON po.menu_id = m.id
WHERE p.gender = 'male'
  AND (p.address = 'Moscow' OR p.address = 'Samara')
  AND (m.pizza_name = 'pepperoni pizza' OR m.pizza_name = 'mushroom pizza')
ORDER BY p.name DESC;
