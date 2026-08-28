-- Объединяем menu (id, pizza_name) и person (id, name) в один список.
-- UNION уравнивает выборки по позиции колонок и по умолчанию убирает дубликаты строк.
-- Имена итоговых колонок берёт только первый SELECT.
SELECT id AS object_id, pizza_name AS object_name FROM menu
UNION
SELECT id AS object_id, name AS object_name FROM person
ORDER BY object_id, object_name;
