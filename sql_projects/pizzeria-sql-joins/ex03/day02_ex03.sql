-- Тот же ответ, что в ex01, но генератор дат вынесен в CTE. Смысл переписывания
-- не в производительности — план запроса тот же, — а в читаемости: подзапрос
-- получает имя, и в тело запроса попадает date_generator вместо вызова функции
-- с тремя аргументами и приведением типа посреди FROM.
--
-- Приведение ::date сделано один раз внутри CTE, поэтому дальше колонка уже
-- нужного типа и в соединении её приводить не нужно.
WITH date_generator AS (SELECT generate_series('2022-01-01'::date,
                                               '2022-01-10'::date,
                                               '1 day'::interval)::date AS missing_date)
SELECT dg.missing_date
FROM date_generator dg
         LEFT JOIN person_visits pv
                   ON pv.visit_date = dg.missing_date
                       AND (pv.person_id = 1 OR pv.person_id = 2)
WHERE pv.id IS NULL
ORDER BY dg.missing_date;
