# Работа с базами данных

Раздел с проектами по SQL. Здесь запросы, схемы и всё, что связано с реляционными данными, — в отличие от [раздела DevOps](../devops_projects), где база фигурирует лишь как один из контейнеров развёртывания.

---

## Проекты

| Проект | О чём | Технологии |
|---|---|---|
| [Выборки по базе пиццерий](./pizzeria-sql-basics) | Десять запросов к базе из пяти связанных таблиц. Фильтрация, вычисляемые поля, `CASE`, подзапросы в `SELECT` и `FROM`. Часть заданий запрещает `JOIN` и `IN`, поэтому таблицы связываются вручную | ![PostgreSQL](https://img.shields.io/badge/PostgreSQL-4169E1?style=flat-square&logo=postgresql&logoColor=white) ![ANSI SQL](https://img.shields.io/badge/ANSI%20SQL-336791?style=flat-square) ![Bash](https://img.shields.io/badge/Bash-4EAA25?style=flat-square&logo=gnu-bash&logoColor=white) |
| [Множества и соединения таблиц](./pizzeria-sql-sets) | Одиннадцать запросов к той же базе. Операторы множеств `UNION`, `INTERSECT`, `EXCEPT` против соединений `JOIN` и `NATURAL JOIN`. Два журнала событий не связаны ключом, поэтому часть вопросов решается только пересечением множеств | ![PostgreSQL](https://img.shields.io/badge/PostgreSQL-4169E1?style=flat-square&logo=postgresql&logoColor=white) ![ANSI SQL](https://img.shields.io/badge/ANSI%20SQL-336791?style=flat-square) ![Bash](https://img.shields.io/badge/Bash-4EAA25?style=flat-square&logo=gnu-bash&logoColor=white) |
| [Соединения таблиц вглубь](./pizzeria-sql-joins) | Одиннадцать запросов к той же базе. Типы соединений, CTE и обработка `NULL`: чем `LEFT` отличается от `FULL`, почему условие в `ON` и то же условие в `WHERE` дают разный результат. Первые четыре задания запрещают `NOT IN` и `NOT EXISTS`, и разность множеств выражается анти-джойном | ![PostgreSQL](https://img.shields.io/badge/PostgreSQL-4169E1?style=flat-square&logo=postgresql&logoColor=white) ![ANSI SQL](https://img.shields.io/badge/ANSI%20SQL-336791?style=flat-square) ![Bash](https://img.shields.io/badge/Bash-4EAA25?style=flat-square&logo=gnu-bash&logoColor=white) |

---

## Как устроен каждый проект

```
<проект>/
├── README.md         обзор, схема базы, разбор решений
├── main_report.md    подробный разбор с запросами и фактическим выводом
└── <запросы>         файлы .sql и скрипт прогона
```

Схемы и наборы тестовых данных выданы курсом и в репозиторий не входят — публикуются только собственные запросы и скрипты. Условия заданий тоже не публикуются, их формулировки пересказаны в отчётах.

Отчёты строятся на фактическом выводе: запросы прогоняются на локальном PostgreSQL заново, результаты вставляются как есть.

---

Author: [Alexander Stepanovich](https://github.com/sher2yja)
