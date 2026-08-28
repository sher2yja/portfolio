-- Нужны уникальные pizza_name, но DISTINCT/GROUP BY/HAVING/JOIN запрещены.
-- UNION таблицы с самой собой убирает дубликаты "бесплатно" — это его стандартная
-- семантика множества, а не отдельная команда.
SELECT pizza_name FROM menu
UNION
SELECT pizza_name FROM menu
ORDER BY pizza_name DESC;
