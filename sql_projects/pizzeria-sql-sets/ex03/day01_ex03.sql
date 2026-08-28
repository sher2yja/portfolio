-- Ищем пары (дата, person_id), встречающиеся и среди заказов, и среди визитов —
-- человека, который в этот день и заходил в пиццерию, и заказывал пиццу.
-- JOIN не подходит: у person_order и person_visits нет общего внешнего ключа,
-- только совпадение по паре значений — это пересечение множеств, INTERSECT.
-- Без ALL: нужны уникальные пары, кратность не важна.
SELECT order_date AS action_date, person_id FROM person_order
INTERSECT
SELECT visit_date AS action_date, person_id FROM person_visits
ORDER BY action_date ASC, person_id DESC;
