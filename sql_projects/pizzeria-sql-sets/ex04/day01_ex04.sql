-- Разность person_id между заказами и визитами за 7 января, с сохранением дублей.
-- EXCEPT ALL вычитает построчно, как мультимножества: если слева "4" встретилась
-- 3 раза, а справа — 1 раз, останется 2 копии "4". Обычный EXCEPT сначала свёл бы
-- обе стороны к множествам — {4,8} и {4,8} — и вернул бы вообще пусто.
SELECT person_id FROM person_order WHERE order_date = '2022-01-07'
EXCEPT ALL
SELECT person_id FROM person_visits WHERE visit_date = '2022-01-07';
