# ⚙️ Kubernetes: манифесты для приложения из 7 микросервисов

### 📌 Обзор проекта

Приложение из 7 микросервисов на Spring Boot, PostgreSQL и RabbitMQ разворачивается в кластер **Kubernetes** собственным набором манифестов — от Namespace до Deployment. Стенд локальный, на **minikube**.

Отдельная часть работы — замер времени переразвёртывания двумя стратегиями, `Recreate` и `RollingUpdate`, на одном и том же приложении.

Это первый проект Kubernetes-ветки: здесь пишутся сырые манифесты и применяются вручную. Дальше те же объекты собираются в собственный кластер k3s, а затем параметризуются через Kustomize и Helm.

---

### 🛠 Стек технологий

![Kubernetes](https://img.shields.io/badge/Orchestration-Kubernetes-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white)
![minikube](https://img.shields.io/badge/Cluster-minikube-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white)
![Docker](https://img.shields.io/badge/Driver-Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/DB-PostgreSQL-4169E1?style=for-the-badge&logo=postgresql&logoColor=white)
![RabbitMQ](https://img.shields.io/badge/Broker-RabbitMQ-FF6600?style=for-the-badge&logo=rabbitmq&logoColor=white)
![Bash](https://img.shields.io/badge/Script-Bash-4EAA25?style=for-the-badge&logo=gnu-bash&logoColor=white)

---

### 🏗 Что разворачивается

```
                   minikube (4 GB, драйвер docker)
                              │
                   kubectl apply -f ./manifests/
                              │
   ┌──────────────────────────┴───────────────────────────┐
   │              namespace: basic-kuber                  │
   │                                                      │
   │   ConfigMap environments      Secret svc-secrets      │
   │   (хосты, порты, имена БД)    (учётные данные, ключи) │
   │            │                          │              │
   │            └──────────┬───────────────┘              │
   │                       │  envFrom                     │
   │                       ▼                              │
   │   ┌─────────────────────────────────────────────┐    │
   │   │  gateway-svc  :8087   NodePort ──► снаружи  │    │
   │   │      │                                      │    │
   │   │      ├──► hotel-svc    :8082                │    │
   │   │      ├──► booking-svc  :8083 ──┐            │    │
   │   │      ├──► payment-svc  :8084   │            │    │
   │   │      ├──► loyalty-svc  :8085   │ RabbitMQ   │    │
   │   │      └──► report-svc   :8086 ◄─┘            │    │
   │   │                                             │    │
   │   │  session-svc  :8081   NodePort ──► снаружи  │    │
   │   └──────────────────┬──────────────────────────┘    │
   │                      │                               │
   │                      ▼                               │
   │   PostgreSQL :5432 — 6 баз, по одной на сервис        │
   │   init.sql из ConfigMap database-script               │
   └──────────────────────────────────────────────────────┘
```

Наружу выведены только два сервиса — `session` и `gateway`: именно к ним обращаются функциональные тесты. Остальные семь остаются `ClusterIP` и доступны только изнутри кластера.

---

### 🚀 Ключевые этапы реализации

* **Порядок применения задан именами файлов.** `kubectl apply -f ./manifests/` обходит каталог в алфавитном порядке, поэтому файлы пронумерованы `01`…`05`. Namespace должен существовать раньше объектов внутри него, ConfigMap и Secret — раньше подов, которые на них ссылаются, иначе поды поднимутся в `CreateContainerConfigError`.

* **Одна карта конфигурации на девять сервисов.** В `environments` собраны хосты и порты; имена хостов совпадают с именами Service, и внутренний DNS кластера резолвит их сам. Общего ключа `POSTGRES_DB` нет: база у каждого сервиса своя, и нужный ключ каждый Deployment подставляет через `configMapKeyRef` поверх общего `envFrom`.

* **Инициализация базы через ConfigMap.** SQL создания шести баз лежит в ConfigMap и монтируется в контейнер PostgreSQL как `/docker-entrypoint-initdb.d/`. Скрипт написан идемпотентно, с `DROP DATABASE IF EXISTS`: том у базы временный, при каждом пересоздании пода всё разворачивается заново.

* **Наружу выведено ровно необходимое.** `NodePort` только у двух сервисов из девяти, доступ к ним на время тестов пробрасывается через `kubectl port-forward`.

* **Замер, который меряет то, что нужно.** `kubectl apply` возвращается почти мгновенно — он лишь отправляет манифест в API, раскатка идёт асинхронно. Поэтому `deploy.sh` замеряет не его, а ожидание `kubectl rollout status` по каждому Deployment. Цикл идёт по всем Deployment в namespace, а не по списку имён.

* **Сравнение стратегий.** `Recreate` — 62 секунды, `RollingUpdate` — 39. Разница в механике: `Recreate` гасит все старые поды и только потом поднимает новые, а Spring Boot стартует 15–35 секунд; `RollingUpdate` с `maxSurge: 1` держит новый под рядом со старым и переключается после готовности.

---

### 📂 Что в папке

| Путь | Назначение |
|---|---|
| `manifests/01-namespace.yaml` | Namespace `basic-kuber` |
| `manifests/02-configmap.yaml` | карта конфигурации и init-скрипт на 6 баз |
| `manifests/03-secrets.yaml` | учётные данные БД и брокера, ключи авторизации |
| `manifests/04-services.yaml` | 9 Service, два из них NodePort |
| `manifests/05-deployments.yaml` | 9 Deployment, обе стратегии развёртывания |
| `deploy.sh` | применение манифестов с замером времени раскатки |
| `main_report.md` | отчёт о прогоне: команды, вывод, скриншоты |
| `images/` | 39 скриншотов работы стенда |

Учебный манифест из первой части задания в репозиторий не входит — он выдан курсом. Исходный код микросервисов тоже: публикуется только то, что написано самостоятельно.

> Секреты в манифестах — учебные заглушки для локального стенда (`postgres/postgres`, `guest/guest`). Пара RSA-ключей для подписи JWT заменена заглушкой, команда генерации своей — в шапке `03-secrets.yaml`.

---

### 📈 Итоговый результат

Приложение разворачивается в кластер одной командой и проходит функциональные тесты. Состояние всех объектов — секретов, карт конфигурации, подов, развёртываний и сервисов — проверено через `kubectl` и панель управления. Обе стратегии развёртывания замерены на одном приложении.

Главное, что даёт проект дальше, — понимание, что манифест описывает **желаемое состояние**, а не последовательность действий. Отсюда и требование к порядку применения, и разница между стратегиями: Kubernetes приводит кластер к описанному состоянию тем способом, который ему задан, и способ этот стоит выбирать осознанно.
