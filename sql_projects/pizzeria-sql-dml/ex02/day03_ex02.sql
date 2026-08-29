-- То же множество невостребованных позиций, но с названиями и ценами.
-- Условие из ex01 не изменилось; добавилось только соединение с pizzeria,
-- чтобы назвать заведение. В самом ex01 такое соединение было бы нарушением
-- запрета, здесь ограничений нет.
SELECT m.pizza_name,
       m.price,
       pz.name AS pizzeria_name
FROM menu m
         JOIN pizzeria pz ON pz.id = m.pizzeria_id
WHERE m.id NOT IN (SELECT menu_id FROM person_order)
ORDER BY m.pizza_name, m.price;
