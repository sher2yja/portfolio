-- Пиццерии, которые никто не посещал — два способа получить один и тот же ответ.

-- через IN: id пиццерии не входит в список посещённых id.
-- NOT IN безопасен здесь, т.к. person_visits.pizzeria_id объявлен NOT NULL —
-- будь там NULL, всё условие NOT IN тихо стало бы неопределённым и результат был бы пустым.
SELECT * FROM pizzeria
WHERE id NOT IN (SELECT pizzeria_id FROM person_visits);

-- через EXISTS: для каждой пиццерии проверяем, есть ли хоть один визит.
-- NOT EXISTS не подвержен ловушке с NULL, поэтому в реальных базах считается
-- более надёжным выбором по умолчанию.
SELECT * FROM pizzeria pz
WHERE NOT EXISTS (
    SELECT 1 FROM person_visits pv WHERE pv.pizzeria_id = pz.id
);
