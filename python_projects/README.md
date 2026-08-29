# Python

Раздел с проектами на Python. Здесь язык — предмет работы, а не инструмент
автоматизации: в [разделе DevOps](../devops_projects) скрипты обслуживают стенд,
здесь же разбирается сам язык — его модель параллелизма, стандартная библиотека
и то, чем процессы отличаются от корутин.

---

## Проекты

| Проект | О чём | Технологии |
|---|---|---|
| [Параллельность: процессы и корутины](./python-concurrency) | Две программы на одну тему. Экзамен, где каждый экзаменатор работает в своём процессе, а общее состояние живёт под `Manager` и замком. И асинхронный загрузчик изображений, который принимает следующую ссылку, не дожидаясь предыдущей загрузки | ![Python](https://img.shields.io/badge/Python-3776AB?style=flat-square&logo=python&logoColor=white) ![multiprocessing](https://img.shields.io/badge/multiprocessing-3776AB?style=flat-square&logo=python&logoColor=white) ![asyncio](https://img.shields.io/badge/asyncio-3776AB?style=flat-square&logo=python&logoColor=white) ![aiohttp](https://img.shields.io/badge/aiohttp-2C5BB4?style=flat-square&logo=aiohttp&logoColor=white) |
| [Десять задач: алгоритмы и ограничения](./python-algorithms) | Динамика, заливка связной области, слияние отсортированных списков, разбор строки в число без `float()`. Только стандартная библиотека. Интереснее алгоритмов здесь ограничения условия: они же определяют форму каждого решения, на них же нашёлся единственный дефект проекта | ![Python](https://img.shields.io/badge/Python-3776AB?style=flat-square&logo=python&logoColor=white) ![stdlib](https://img.shields.io/badge/stdlib%20only-3776AB?style=flat-square&logo=python&logoColor=white) ![JSON](https://img.shields.io/badge/JSON-000000?style=flat-square&logo=json&logoColor=white) |

---

## Как устроен каждый проект

```
<проект>/
├── README.md         обзор, стек, схемы, ключевые решения
├── main_report.md    подробный разбор с фактическим выводом программ
├── run.sh / run.py   запуск, а где есть зависимости — и окружение
└── <код>             модули и входные данные
```

Условия заданий не публикуются, их формулировки пересказаны в отчётах своими словами.

Отчёты строятся на фактическом выводе: программы запускаются заново, вывод вставляется
как есть. Там, где правило вероятностное, оно подтверждается не одним прогоном,
а замером на десятках тысяч — это возможно потому, что модули с правилами не зависят
ни от процессов, ни от ввода-вывода.

---

Author: [Alexander Stepanovich](https://github.com/sher2yja)
