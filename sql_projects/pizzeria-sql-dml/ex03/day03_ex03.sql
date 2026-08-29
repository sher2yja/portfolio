-- Пиццерии, где перевес визитов у одного пола. Считается как разность
-- мультимножеств в обе стороны и объединение результатов.
--
-- Ключ к заданию — модификатор ALL. Без него каждая сторона свернулась бы
-- в множество названий, и EXCEPT отвечал бы на вопрос «куда ходили женщины,
-- а мужчины не ходили вовсе». С ALL кратность строки означает число визитов:
-- три женских визита минус два мужских дают одну строку — тот самый перевес.
(SELECT pz.name AS pizzeria_name
 FROM person_visits pv
          JOIN person p ON p.id = pv.person_id
          JOIN pizzeria pz ON pz.id = pv.pizzeria_id
 WHERE p.gender = 'female'
 EXCEPT ALL
 SELECT pz.name
 FROM person_visits pv
          JOIN person p ON p.id = pv.person_id
          JOIN pizzeria pz ON pz.id = pv.pizzeria_id
 WHERE p.gender = 'male')
UNION ALL
(SELECT pz.name
 FROM person_visits pv
          JOIN person p ON p.id = pv.person_id
          JOIN pizzeria pz ON pz.id = pv.pizzeria_id
 WHERE p.gender = 'male'
 EXCEPT ALL
 SELECT pz.name
 FROM person_visits pv
          JOIN person p ON p.id = pv.person_id
          JOIN pizzeria pz ON pz.id = pv.pizzeria_id
 WHERE p.gender = 'female')
ORDER BY pizzeria_name;
