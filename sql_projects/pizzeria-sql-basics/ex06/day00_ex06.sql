-- Задание 06: Погружение в мир SQL
/* Используй конструкцию SQL из Задания 05 и добавь в оператор SELECT новый вычисляемый столбец с именем check_name. 
В этом столбце реализуй проверку по следующему псевдокоду:

if (person_name == 'Denis'), вернуть true,
иначе вернуть false.*/

SELECT
--  пишу подзапрос чтобы
--   выбрать имя из таблицы где id совпадает c person_id из т person_order
    (SELECT name FROM person WHERE id = person_order.person_id) AS NAME,
    -- добавляю case, оператор который альтернатива if
        CASE
        -- когда наш селект = Денис
        WHEN (SELECT name FROM person WHERE id = person_order.person_id) = 'Denis'
        -- тогда истина иначе - иначе
        THEN true
        ELSE false
    END AS check_name
FROM person_order
WHERE person_order.order_date = '2022-01-07' and (person_order.menu_id = 13 or person_order.menu_id = 14 or person_order.menu_id = 18);