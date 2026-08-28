-- Тот же вопрос, что в ex03 (пересечение заказов и визитов по дате/person_id),
-- но нужно имя человека, а не id. Сначала множества решают, какие строки нужны
-- (INTERSECT спрятан в подзапросе t), а JOIN потом просто подставляет имя вместо id.
SELECT t.action_date, p.name AS person_name
FROM (
    SELECT order_date AS action_date, person_id FROM person_order
    INTERSECT
    SELECT visit_date AS action_date, person_id FROM person_visits
) t
JOIN person p ON p.id = t.person_id
ORDER BY t.action_date ASC, person_name DESC;
