-- Дни с 1 по 10 января, в которые не ходил ни человек 1, ни человек 2.
-- Пропуск в данных — это отсутствующая строка, а искать по отсутствующему
-- нечем: сначала генерируем полный ряд дат, и только потом ищем, чего в нём
-- нет. generate_series возвращает timestamp, поэтому приведение ::date
-- обязательно — иначе сравнение с visit_date (тип date) шло бы по времени.
--
-- Условие на человека стоит в ON, а не в WHERE: в WHERE оно отбросило бы
-- строки, где пары не нашлось (там person_id = NULL), и анти-джойн выродился
-- бы в обычное внутреннее соединение — результат стал бы пустым.
SELECT gs.missing_date::date AS missing_date
FROM generate_series('2022-01-01'::date, '2022-01-10'::date, '1 day'::interval) AS gs(missing_date)
         LEFT JOIN person_visits pv
                   ON pv.visit_date = gs.missing_date::date
                       AND (pv.person_id = 1 OR pv.person_id = 2)
WHERE pv.id IS NULL
ORDER BY missing_date;
