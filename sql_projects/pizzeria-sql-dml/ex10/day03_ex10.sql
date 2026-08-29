-- Заказы тех же двоих на пиццу из ex08. Схема та же, что в ex09, но ссылка
-- ведёт не на пиццерию, а на позицию меню — заказ связан именно с ней.
--
-- Позиция ищется по названию, потому что её id заранее неизвестен: он появился
-- в ex08 как max(id) + 1 и в тексте задания не назван.
INSERT INTO person_order (id, person_id, menu_id, order_date)
SELECT (SELECT max(id) FROM person_order) + row_number() OVER (ORDER BY p.id),
       p.id,
       (SELECT id FROM menu WHERE pizza_name = 'sicilian pizza'),
       '2022-02-24'
FROM person p
WHERE p.name IN ('Denis', 'Irina');
