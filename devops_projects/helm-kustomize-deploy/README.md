# ⎈ Helm и Kustomize: два способа доставки одного приложения

### 📌 Обзор проекта

Приложение из 7 микросервисов на Spring Boot разворачивается в кластер k3s двумя независимыми путями: через **Kustomize** (base + overlay) и через собственный **Helm-чарт**. Кластер из трёх виртуальных машин поднимается одной командой `vagrant up` и сам себя провижинит.

Смысл задачи — не «задеплоить», а сравнить два подхода к параметризации манифестов на одном и том же приложении и увидеть, где каждый удобнее.

Отдельная часть работы — **передача уже работающих объектов под управление Helm без простоя**. Приложение в кластере разворачивается автоматически через `kubectl apply`, поэтому у объектов нет метаданных владения Helm, и прямой `helm install` падает с `invalid ownership metadata`. Решено усыновлением: проставить объектам нужные лейблы и аннотации на месте, вместо удаления и переустановки.

---

### 🛠 Стек технологий

![Kubernetes](https://img.shields.io/badge/Orchestration-Kubernetes-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white)
![k3s](https://img.shields.io/badge/Distribution-k3s-FFC61C?style=for-the-badge&logo=k3s&logoColor=black)
![Helm](https://img.shields.io/badge/Packaging-Helm-0F1689?style=for-the-badge&logo=helm&logoColor=white)
![Kustomize](https://img.shields.io/badge/Config-Kustomize-7B42BC?style=for-the-badge&logo=kubernetes&logoColor=white)
![Vagrant](https://img.shields.io/badge/IaC-Vagrant-1868F2?style=for-the-badge&logo=vagrant&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/DB-PostgreSQL-4169E1?style=for-the-badge&logo=postgresql&logoColor=white)
![RabbitMQ](https://img.shields.io/badge/Broker-RabbitMQ-FF6600?style=for-the-badge&logo=rabbitmq&logoColor=white)
![NGINX](https://img.shields.io/badge/Ingress-NGINX-009639?style=for-the-badge&logo=nginx&logoColor=white)

---

### 🏗 Архитектура стенда

```
                    хост-машина (libvirt)
                            │
                  vagrant up --provider=libvirt
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
   ┌────┴─────┐      ┌──────┴─────┐      ┌──────┴─────┐
   │  master  │      │  worker1   │      │  worker2   │
   │ .33.10   │      │  .33.11    │      │  .33.12    │
   │ k3s      │◄─────┤ k3s agent  │      │ k3s agent  │
   │ server   │      │            │      │            │
   │          │      │ /mnt/data/ │      │            │
   │ traefik  │      │  postgres  │      │            │
   │ выключен │      │  (hostPath)│      │            │
   └────┬─────┘      └──────┬─────┘      └────────────┘
        │                   │
        │            nodeSelector привязывает
        │            Postgres строго к worker1,
        │            чтобы совпасть с hostPath PV
        │
   ┌────┴──────────────────────────────────────────┐
   │           namespace: basic-kuber              │
   │                                               │
   │  ingress-nginx ──► sherryja.school21          │
   │    ├─ /api/v1/auth    ──► session-service:8081│
   │    └─ /api/v1/gateway ──► gateway-service:8087│
   │                                               │
   │  gateway ──► hotel, booking, payment,         │
   │              loyalty, report                  │
   │  booking ──► RabbitMQ ──► report              │
   │  все     ──► PostgreSQL (6 БД, по одной       │
   │              на сервис)                       │
   │                                               │
   │  TLS: cert-manager + self-signed ClusterIssuer│
   └───────────────────────────────────────────────┘
```

Traefik в k3s отключён намеренно — вместо него ставится ingress-nginx, потому что задание требует работы с привычным Ingress-контроллером. cert-manager ставится отдельно: в базовой поставке k3s нет CRD `ClusterIssuer` и `Certificate`.

---

### 🚀 Ключевые этапы реализации

* **Автоматизация стенда.** `Vagrantfile` поднимает 3 VM со статическими IP, скрипты провижининга ставят k3s server и подключают агентов. Триггер `trigger.after :up` объявлен внутри ветки конкретной машины, а не глобально — иначе в мульти-машинном окружении деплой запускается по разу на каждую VM.

* **Kustomize: base + overlay.** В `base/` — общее для всех окружений (Namespace, Deployment, Service, PV/PVC, Ingress, Certificate), в `overlays/production/` — ConfigMap, Secret и патч реплик. Глобальный `namespace:`-трансформер сознательно не используется: он проставил бы `metadata.namespace` на cluster-scoped ресурсы (`PersistentVolume`, `ClusterIssuer`), что для них невалидно.

* **Strategic merge patch.** `replicas-patch.yaml` меняет число реплик `gateway-svc` с 1 на 3 — минимальный патч, демонстрирующий смысл оверлея: база остаётся нетронутой, окружение переопределяет только нужное поле.

* **Helm-чарт вместо девяти копий шаблона.** Заготовка от `helm create` полностью переписана: вместо девяти почти одинаковых манифестов — одна карта `services:` в `values.yaml` и два шаблона с `range`, генерирующие все 9 Deployment и 9 Service. Namespace в чарт не зашит, задаётся флагом `--namespace`.

* **Усыновление объектов без простоя.** `scripts/helm-adopt.sh` проставляет `app.kubernetes.io/managed-by=Helm` и аннотации `meta.helm.sh/release-*` на 18 существующих объектов, после чего `helm install` принимает их как свои. Поле `containerName` в `values.yaml` понадобилось именно здесь: у контейнера БД имя не совпадает с именем Deployment, и без явного указания patch добавлял второй контейнер вместо замены.

* **Диагностика гонки на старте.** Readiness-проб у Deployment нет, а Spring Boot поднимается 15–35 секунд, поэтому тесты сразу после `1/1 Running` получают 502. `scripts/checksvc.sh` ждёт строку `Started ...Application in` в логах всех сервисов.

---

### 📂 Что в папке

| Путь | Назначение |
|---|---|
| `Vagrantfile` | 3 VM со статическими IP, провижининг, триггер деплоя |
| `scripts/k3s-master.sh`, `k3s-worker.sh` | установка k3s server и подключение агентов |
| `scripts/deploy-app.sh` | ingress-nginx, cert-manager и применение манифестов в порядке зависимостей |
| `scripts/helm-adopt.sh` | передача существующих объектов под управление Helm |
| `scripts/checksvc.sh` | ожидание реальной готовности Spring Boot-сервисов |
| `k3s/` | сырые манифесты — то, что применяется автоматически при `vagrant up` |
| `base/`, `overlays/production/`, `kustomization.yaml` | Kustomize: 27 объектов на выходе |
| `helm/myapp/` | Helm-чарт: `values.yaml` + 2 шаблона с `range`, 18 объектов |
| `main_report.md` | отчёт о прогоне: команды, вывод, скриншоты |
| `images/` | 19 скриншотов работы стенда |

Три набора манифестов описывают **одно и то же приложение** и не заменяют друг друга: `k3s/` применяется автоматикой, Kustomize и Helm — вручную. Kustomize даёт 27 объектов, чарт — только 18 (Deployment + Service), остальное берётся из уже развёрнутого базового набора.

> Секреты в манифестах — учебные заглушки для локального стенда (`postgres/postgres`, `guest/guest`). Это не пример работы с секретами в проде.

---

### 📈 Итоговый результат

Приложение разворачивается обоими способами и проходит функциональные тесты. Helm-чарт проходит `helm lint` без ошибок, при рендере даёт ровно 18 объектов; сборка Kustomize — 27. Релиз установлен в тот же namespace, где приложение уже работало, **без удаления объектов и без простоя**, изменение `values.yaml` применено через `helm upgrade` и подтверждено переходом релиза на вторую ревизию.

Самое полезное из проекта — не команды Helm, а понимание, что манифест в кластере имеет владельца. Пока объект создан через `kubectl apply`, Helm его своим не считает, и переход на пакетный менеджер в живой системе — отдельная задача, а не `helm install` поверх.

**Проверка чарта локально, без кластера:**
```bash
helm lint helm/myapp
helm template do12 helm/myapp --namespace basic-kuber | grep -c '^kind:'   # 18
kustomize build overlays/production | grep -c '^kind:'                     # 27
```
