-- Тот же список, что в ex00, но без object_id и с сохранением дублей.
-- 'block' — служебная колонка только для сортировки (1 = person, 2 = menu),
-- поэтому сначала идут все имена людей, потом все пиццы, каждый блок — по алфавиту.
-- UNION ALL обязателен: в menu "cheese pizza" встречается у 6 разных пиццерий,
-- это настоящие дубликаты строк, и обычный UNION схлопнул бы их в одну.
SELECT object_name
FROM (
    SELECT name AS object_name, 1 AS block FROM person
    UNION ALL
    SELECT pizza_name AS object_name, 2 AS block FROM menu
) t
ORDER BY block, object_name;
