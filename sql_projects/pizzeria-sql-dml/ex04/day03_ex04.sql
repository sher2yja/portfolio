-- Пиццерии, где заказывали только женщины, плюс те, где заказывали только
-- мужчины. Внешне запрос повторяет ex03, но здесь операторы идут БЕЗ ALL —
-- и это меняет смысл, а не оформление.
--
-- Без ALL обе стороны становятся множествами названий, и разность отвечает
-- «здесь заказывал этот пол и не заказывал другой» — то самое «только».
-- С ALL, как в ex03, получился бы перевес по числу заказов, то есть другой
-- ответ на другой вопрос.
(SELECT pz.name AS pizzeria_name
 FROM person_order po
          JOIN person p ON p.id = po.person_id
          JOIN menu m ON m.id = po.menu_id
          JOIN pizzeria pz ON pz.id = m.pizzeria_id
 WHERE p.gender = 'female'
 EXCEPT
 SELECT pz.name
 FROM person_order po
          JOIN person p ON p.id = po.person_id
          JOIN menu m ON m.id = po.menu_id
          JOIN pizzeria pz ON pz.id = m.pizzeria_id
 WHERE p.gender = 'male')
UNION
(SELECT pz.name
 FROM person_order po
          JOIN person p ON p.id = po.person_id
          JOIN menu m ON m.id = po.menu_id
          JOIN pizzeria pz ON pz.id = m.pizzeria_id
 WHERE p.gender = 'male'
 EXCEPT
 SELECT pz.name
 FROM person_order po
          JOIN person p ON p.id = po.person_id
          JOIN menu m ON m.id = po.menu_id
          JOIN pizzeria pz ON pz.id = m.pizzeria_id
 WHERE p.gender = 'female')
ORDER BY pizzeria_name;
