-- Задание 09: Погружение в мир SQL
/*Составь запрос SELECT, который вернет имена людей и названия пиццерий на основе таблицы person_visits 
с датами посещений в период с 7 по 9 января 2022 года (включительно), используя внутренний запрос в части FROM.

Обрати внимание на структуру итогового запроса:

SELECT (...) AS person_name ,  -- внутренний запрос в основном SELECT
        (...) AS pizzeria_name  -- внутренний запрос в основном SELECT
FROM (SELECT … FROM person_visits WHERE …) AS pv -- внутренний запрос в основном FROM
ORDER BY ...
Добавь сортировку по имени человека в порядке возрастания и по названию пиццерии в порядке убывания.*/

-- Задание запрещает JOIN, поэтому связка трёх таблиц собрана из подзапросов:
-- отбор посещений вынесен в подзапрос в части FROM, а имена человека и пиццерии
-- достаются скалярными подзапросами в части SELECT.
--
-- Псевдоним pv обязателен: подзапрос в FROM без имени PostgreSQL не принимает,
-- и без него не на что было бы сослаться из внешнего SELECT.
SELECT 
    (SELECT name FROM person WHERE id = pv.person_id) AS person_name,
    (SELECT name FROM pizzeria WHERE id = pv.pizzeria_id) AS pizzeria_name
FROM (
    SELECT person_id, pizzeria_id
    FROM person_visits
    WHERE visit_date BETWEEN '2022-01-07' AND '2022-01-09'
    ) AS pv
ORDER BY person_name ASC, pizzeria_name DESC;