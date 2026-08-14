# ☸️ Собственный кластер k3s: Ingress, TLS и постоянное хранилище

### 📌 Обзор проекта

Кластер Kubernetes собирается с нуля на трёх виртуальных машинах: один control plane и два рабочих узла на дистрибутиве **k3s**. Штатный Ingress-контроллер отключается и заменяется на NGINX, для домена выпускается wildcard-сертификат через **cert-manager**, база данных переводится с временного тома на постоянный, а метрики собирает **Prometheus Operator**.

В предыдущем проекте приложение разворачивалось в готовый кластер. Здесь кластер строится сам — вместе с сетью, точкой входа, сертификатами и хранилищем.

---

### 🛠 Стек технологий

![k3s](https://img.shields.io/badge/Distribution-k3s-FFC61C?style=for-the-badge&logo=k3s&logoColor=black)
![Kubernetes](https://img.shields.io/badge/Orchestration-Kubernetes-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white)
![NGINX](https://img.shields.io/badge/Ingress-NGINX-009639?style=for-the-badge&logo=nginx&logoColor=white)
![cert-manager](https://img.shields.io/badge/TLS-cert--manager-326CE5?style=for-the-badge&logo=letsencrypt&logoColor=white)
![Vagrant](https://img.shields.io/badge/IaC-Vagrant-1868F2?style=for-the-badge&logo=vagrant&logoColor=white)
![Prometheus](https://img.shields.io/badge/Metrics-Prometheus-E6522C?style=for-the-badge&logo=prometheus&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/DB-PostgreSQL-4169E1?style=for-the-badge&logo=postgresql&logoColor=white)
![RabbitMQ](https://img.shields.io/badge/Broker-RabbitMQ-FF6600?style=for-the-badge&logo=rabbitmq&logoColor=white)

---

### 🏗 Архитектура стенда

```
                      хост-машина
                           │
                      vagrant up
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
   ┌────┴─────┐     ┌──────┴─────┐     ┌──────┴──────┐
   │  master  │     │  worker1   │     │   worker2   │
   │ .56.10   │     │  .56.11    │     │   .56.12    │
   │          │◄────┤ k3s agent  │◄────┤ k3s agent   │
   │ k3s      │     │            │     │             │
   │ server   │     │  ingress-  │     │  PostgreSQL │
   │          │     │   nginx    │     │  /data/     │
   │ traefik  │     │            │     │   postgres  │
   │ выключен │     │            │     │  (hostPath) │
   └──────────┘     └────────────┘     └──────┬──────┘
                                              │
                          точка входа домена  │
                                              │
   ┌──────────────────────────────────────────┴──────┐
   │        api.192.168.56.12.nip.io  (HTTPS)        │
   │                                                 │
   │  Ingress NGINX + wildcard-tls                   │
   │    ├─ /api/v1/auth    ──► session-service:8081  │
   │    └─ /api/v1/gateway ──► gateway-service:8087  │
   │                                                 │
   │  gateway ──► hotel, booking, payment,           │
   │              loyalty, report                    │
   │  booking ──► RabbitMQ ──► report                │
   │  все     ──► PostgreSQL (6 БД, по одной         │
   │              на сервис, на PV)                  │
   └─────────────────────────────────────────────────┘
```

Публичного IP у стенда нет, поэтому домен берётся у wildcard-DNS сервиса `nip.io`: имя `api.192.168.56.12.nip.io` резолвится в адрес, зашитый в самом имени. Регистрировать домен и править DNS-записи не требуется.

---

### 🚀 Ключевые этапы реализации

* **Кластер одной командой.** `Vagrantfile` поднимает 3 VM со статическими адресами, каждая получает свой скрипт установки. Токен подключения мастер записывает в общий каталог `/vagrant`, воркеры ждут его появления в цикле — Vagrant стартует машины последовательно, и без ожидания агент пытался бы подключиться раньше, чем сервер сгенерирует токен.

* **Flannel через явный интерфейс.** У каждой VM два интерфейса: NAT `eth0`, одинаковый у всех трёх машин, и private network `eth1`. Без флага `--flannel-iface=eth1` overlay-сеть уходит в NAT, и поды на разных узлах перестают видеть друг друга — при этом `kubectl get nodes` показывает здоровый кластер. Симптом на сетевую проблему не похож, лечится одним флагом.

* **Замена Ingress-контроллера.** Traefik отключается при установке (`--disable traefik`), вместо него применяется официальный манифест ingress-nginx. Контроллер разворачивается на `worker1` и публикует NodePort для HTTP и HTTPS.

* **Wildcard-сертификат без публичного домена.** Let's Encrypt проверку пройти не может — домен не публичный. Поэтому cert-manager настроен на self-signed `ClusterIssuer`: браузер такому сертификату не доверяет, но выпуск, хранение в секрете `kubernetes.io/tls` и терминация TLS на Ingress работают штатно.

* **PersistentVolume вместо `emptyDir`.** База переезжает на том типа `hostPath`. Так как это каталог на диске конкретной машины, том привязывается к `worker2` через `nodeAffinity`, а сам под — через `nodeSelector`. Без этой пары планировщик может запустить PostgreSQL на другом узле, где база молча поднимется пустой.

* **Постоянное хранилище меняет настройку приложения.** Пока база обнулялась при каждом рестарте, Hibernate в режиме `ddl-auto: create` был безобиден. С постоянным томом тот же режим стал бы затирать данные при старте каждого сервиса — потребовался переход на `update`.

* **Prometheus Operator.** Стек `kube-prometheus-stack` ставится Helm-чартом в отдельный namespace: оператор, Prometheus, Alertmanager, Grafana, kube-state-metrics и node-exporter на каждом узле.

---

### 📂 Что в папке

| Путь | Назначение |
|---|---|
| `k3s/Vagrantfile` | 3 VM со статическими IP и провижинингом |
| `k3s/scripts/install_k3s_master.sh` | установка k3s server без Traefik, выгрузка токена |
| `k3s/scripts/install_k3s_worker*.sh` | ожидание токена и подключение агентов |
| `k3s/issuer.yml`, `k3s/certificate.yml` | self-signed ClusterIssuer и wildcard-сертификат |
| `k3s/ingress.yml` | маршрутизация домена с TLS на session и gateway |
| `k3s/postgres-pv.yml`, `k3s/postgres-pvc.yml` | постоянный том для базы и заявка на него |
| `k3s/my-app/` | манифесты приложения: ConfigMap, Secret, PostgreSQL, RabbitMQ |
| `k3s/my-app/services/` | 7 микросервисов, по Deployment и Service на каждый |
| `main_report.md` | отчёт о прогоне: команды, вывод, скриншоты |
| `images/` | 17 скриншотов работы стенда |

Двух вещей в репозитории нет намеренно. Файл `token` генерируется мастером при каждом развёртывании и представляет собой действующий ключ подключения узла к кластеру. Пара RSA-ключей для подписи JWT заменена на заглушку — команда генерации своей приведена в шапке `k3s/my-app/secrets.yml`.

> Остальные секреты в манифестах — учебные заглушки для локального стенда (`postgres/postgres`, `guest/guest`). Это не пример работы с секретами в рабочем проекте.

---

### 📈 Итоговый результат

Кластер собирается одной командой и полностью работоспособен: приложение из 7 микросервисов доступно по доменному имени поверх HTTPS, функциональные тесты проходят все 5 из 5, база данных переживает пересоздание пода без потери данных, в namespace `monitoring` работают 8 подов стека Prometheus.

Главный вывод проекта — про связанность решений. Замена тома у базы выглядит как отдельная инфраструктурная задача, но тянет за собой настройку ORM в приложении; выбор `hostPath` тянет привязку пода к узлу; два сетевых интерфейса на VM тянут явную настройку overlay-сети. Кластер не собирается из независимых кусков.
