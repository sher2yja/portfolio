-- Все варианты, где продаются грибная пицца и пепперони, с ценами.
-- Цена лежит в menu, название заведения — в pizzeria, и связывает их
-- внешний ключ menu.pizzeria_id: одна позиция меню принадлежит ровно одному
-- заведению, поэтому INNER JOIN ничего не размножает и ничего не теряет.
SELECT m.pizza_name,
       pz.name AS pizzeria_name,
       m.price
FROM menu m
         INNER JOIN pizzeria pz ON m.pizzeria_id = pz.id
WHERE m.pizza_name = 'mushroom pizza'
   OR m.pizza_name = 'pepperoni pizza'
ORDER BY m.pizza_name, pizzeria_name;
