-- Пиццерии, которые никто не посещал. Разность множеств без NOT IN и NOT EXISTS:
-- они в этом задании запрещены, и работать приходится одним соединением.
-- LEFT JOIN оставляет строку пиццерии, даже если пары в журнале визитов нет;
-- у таких строк все колонки pv заполнены NULL, и WHERE pv.id IS NULL отбирает
-- ровно их. Проверять на NULL нужно первичный ключ: он объявлен NOT NULL,
-- поэтому NULL в нём означает именно «пары не нашлось», а не пустое значение.
SELECT pz.name,
       pz.rating
FROM pizzeria pz
         LEFT JOIN person_visits pv ON pz.id = pv.pizzeria_id
WHERE pv.id IS NULL
ORDER BY pz.name;
