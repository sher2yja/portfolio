-- Полный список людей и полный список пиццерий за 1–3 января: и те, кто никуда
-- не ходил, и те заведения, куда никто не пришёл. Обе стороны должны уцелеть,
-- поэтому FULL JOIN, а не LEFT: он сохраняет строки без пары слева и справа.
--
-- Отбор по датам убран в подзапрос намеренно. В WHERE внешнего запроса он
-- отбросил бы строки людей без визитов (visit_date у них NULL, а NULL не
-- попадает ни в один диапазон) — то есть ровно то, ради чего брался FULL JOIN.
--
-- COALESCE ставится по условию задания: пропуск в выводе показывается как '-'.
-- В visit_date замены нет — там NULL остаётся NULL, так в образце.
SELECT COALESCE(p.name, '-')  AS person_name,
       pv.visit_date,
       COALESCE(pz.name, '-') AS pizzeria_name
FROM person p
         FULL JOIN (SELECT *
                    FROM person_visits
                    WHERE visit_date BETWEEN '2022-01-01' AND '2022-01-03') pv
                   ON p.id = pv.person_id
         FULL JOIN pizzeria pz ON pz.id = pv.pizzeria_id
ORDER BY person_name, visit_date, pizzeria_name;
