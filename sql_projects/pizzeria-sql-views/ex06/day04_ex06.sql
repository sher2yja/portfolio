-- Материализованное представление: где Дмитрий был 8 января и мог поесть
-- дешевле 800. Запрос тот же, что в проекте про соединения (ex07), но здесь
-- он не выполняется при обращении, а один раз выполняется при создании,
-- и результат ложится на диск как таблица.
--
-- WITH DATA — данные наполняются сразу. С WITH NO DATA представление
-- создалось бы пустым и до первого REFRESH любой запрос к нему падал бы
-- с ошибкой «materialized view has not been populated».
--
-- Отсюда главное свойство: снимок не следит за таблицами. Появится новый
-- подходящий визит — представление продолжит отдавать старый ответ,
-- пока его не обновят. Этим занимается ex07.
--
-- DISTINCT нужен по той же причине, что и в исходном запросе: соединение
-- с меню размножает строку по числу подходящих позиций.
CREATE MATERIALIZED VIEW mv_dmitriy_visits_and_eats AS
SELECT DISTINCT pz.name
FROM person p
         JOIN person_visits pv ON p.id = pv.person_id
         JOIN pizzeria pz ON pz.id = pv.pizzeria_id
         JOIN menu m ON m.pizzeria_id = pz.id
WHERE p.name = 'Dmitriy'
  AND pv.visit_date = '2022-01-08'
  AND m.price < 800
ORDER BY pz.name
WITH DATA;
