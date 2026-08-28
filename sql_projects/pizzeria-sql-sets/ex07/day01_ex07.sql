-- Обычный JOIN по внешнему ключу person_order.person_id = person.id.
-- || склеивает строки в формат "Имя (age:XX)". Сортировка идёт по тексту
-- person_information, а не по возрасту, поэтому "Andrey" может обогнать "Anna".
SELECT po.order_date, p.name || ' (age:' || p.age || ')' AS person_information
FROM person_order po
JOIN person p ON p.id = po.person_id
ORDER BY po.order_date, person_information;
