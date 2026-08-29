-- Что Кейт могла заказать за 800–1000 в тех пиццериях, куда заходила.
-- Меню подключается к пиццерии, а не к заказу: вопрос о доступных ценах,
-- а не о сделанных заказах. Журнал person_order здесь не участвует — по условию
-- модели визит и заказ независимы.
--
-- BETWEEN включает обе границы: пицца ровно за 800 и ровно за 1000 попадают.
SELECT m.pizza_name,
       m.price,
       pz.name AS pizzeria_name,
       pv.visit_date
FROM person_visits pv
         JOIN person p ON p.id = pv.person_id
         JOIN pizzeria pz ON pz.id = pv.pizzeria_id
         JOIN menu m ON m.pizzeria_id = pz.id
WHERE p.name = 'Kate'
  AND m.price BETWEEN 800 AND 1000
ORDER BY m.pizza_name, m.price, pz.name;
