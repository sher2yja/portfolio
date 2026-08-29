-- Женщины, заказывавшие и пепперони, и сырную пиццу — обе, а не любую из них.
-- Одним условием WHERE это не выражается: строка заказа содержит ровно одну
-- пиццу, и требование «pizza_name = A AND pizza_name = B» никогда не истинно.
--
-- Поэтому таблица заказов подключается дважды под разными псевдонимами: одна
-- цепочка ищет пепперони, вторая — сыр, и человек попадает в результат, только
-- если нашлись обе. Условие на пиццу стоит в ON, а не в WHERE: так каждая пара
-- «заказ + позиция меню» фильтруется в момент соединения.
--
-- Два соединения дают внутри человека произведение его заказов (у кого две
-- пепперони и один сыр, получится две строки), поэтому нужен DISTINCT.
SELECT DISTINCT p.name
FROM person p
         INNER JOIN person_order po_pep ON p.id = po_pep.person_id
         INNER JOIN menu m_pep ON po_pep.menu_id = m_pep.id
             AND m_pep.pizza_name = 'pepperoni pizza'
         INNER JOIN person_order po_che ON p.id = po_che.person_id
         INNER JOIN menu m_che ON po_che.menu_id = m_che.id
             AND m_che.pizza_name = 'cheese pizza'
WHERE p.gender = 'female'
ORDER BY p.name;
