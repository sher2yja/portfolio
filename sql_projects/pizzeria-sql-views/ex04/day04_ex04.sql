-- Симметрическая разность двух дней: кто был 2 января или 6 января,
-- но не в оба дня сразу. Формула (R − S) ∪ (S − R) записана буквально.
--
-- Операторы идут без ALL: сравниваются множества идентификаторов, а не
-- количества визитов. С ALL ответ означал бы перевес по числу посещений —
-- другой вопрос, как в дне про DML.
--
-- Представление хранит именно запрос: даты зашиты в определение, и при
-- появлении новых визитов на эти числа результат изменится сам.
CREATE VIEW v_symmetric_union AS
(SELECT person_id
 FROM person_visits
 WHERE visit_date = '2022-01-02'
 EXCEPT
 SELECT person_id
 FROM person_visits
 WHERE visit_date = '2022-01-06')
UNION
(SELECT person_id
 FROM person_visits
 WHERE visit_date = '2022-01-06'
 EXCEPT
 SELECT person_id
 FROM person_visits
 WHERE visit_date = '2022-01-02')
ORDER BY person_id;
