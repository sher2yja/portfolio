-- Декартово произведение: каждая строка person со всеми строками pizzeria,
-- без условия соединения. 9 человек x 6 пиццерий = 54 строки.
SELECT p.*, pz.*
FROM person p
CROSS JOIN pizzeria pz
ORDER BY p.id, pz.id;
