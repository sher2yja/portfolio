-- Куда Дмитрий заходил 8 января и мог заказать пиццу дешевле 800.
-- Вопрос про возможность, а не про факт заказа, поэтому журнал заказов здесь
-- не участвует вовсе: путь идёт person → person_visits → pizzeria → menu.
-- Соединять визиты с заказами по человеку и дате — ловушка модели: по условию
-- задания эти два журнала независимы, человек может сидеть в одном заведении
-- и заказывать по телефону в другом.
--
-- DISTINCT нужен из-за последнего соединения: в меню заведения может оказаться
-- несколько пицц дешевле 800, и одно заведение вернулось бы столько раз,
-- сколько таких позиций нашлось.
SELECT DISTINCT pz.name
FROM person p
         INNER JOIN person_visits pv ON p.id = pv.person_id
         INNER JOIN pizzeria pz ON pv.pizzeria_id = pz.id
         INNER JOIN menu m ON m.pizzeria_id = pz.id
WHERE p.name = 'Dmitriy'
  AND pv.visit_date = '2022-01-08'
  AND m.price < 800
ORDER BY pz.name;
