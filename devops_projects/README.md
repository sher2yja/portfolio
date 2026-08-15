# DevOps и инфраструктура

Двенадцать проектов траектории DevOps: от установки серверной Ubuntu в консоли до Helm-релиза в кластере Kubernetes. Каждый — отдельная папка с README, подробным отчётом и работающими конфигурациями.

Порядок в таблицах — от сложного к базовому, а не хронологический.

---

## Kubernetes и оркестрация

| Проект | О чём | Технологии |
|---|---|---|
| [Helm и Kustomize](./helm-kustomize-deploy) | Одно приложение доставляется двумя независимыми путями: `base` + `overlay` и собственный чарт. Отдельно — передача уже работающих объектов под управление Helm без простоя | ![Helm](https://img.shields.io/badge/Helm-0F1689?style=flat-square&logo=helm&logoColor=white) ![Kustomize](https://img.shields.io/badge/Kustomize-326CE5?style=flat-square&logo=kubernetes&logoColor=white) ![k3s](https://img.shields.io/badge/k3s-FFC61C?style=flat-square&logo=k3s&logoColor=black) ![Vagrant](https://img.shields.io/badge/Vagrant-1868F2?style=flat-square&logo=vagrant&logoColor=white) |
| [Кластер k3s с TLS](./k3s-cluster-tls) | Кластер собирается с нуля на трёх машинах. Штатный Ingress заменяется на NGINX, для домена выпускается wildcard-сертификат, база получает постоянное хранилище | ![k3s](https://img.shields.io/badge/k3s-FFC61C?style=flat-square&logo=k3s&logoColor=black) ![NGINX](https://img.shields.io/badge/NGINX-009639?style=flat-square&logo=nginx&logoColor=white) ![cert-manager](https://img.shields.io/badge/cert--manager-326CE5?style=flat-square) |
| [Микросервисы в Kubernetes](./k8s-microservices) | Приложение из 7 микросервисов разворачивается собственным набором манифестов — от `Namespace` до `Deployment`. Стенд на minikube | ![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=flat-square&logo=kubernetes&logoColor=white) ![minikube](https://img.shields.io/badge/minikube-326CE5?style=flat-square&logo=kubernetes&logoColor=white) ![kubectl](https://img.shields.io/badge/kubectl-326CE5?style=flat-square&logo=kubernetes&logoColor=white) |
| [Compose и Swarm](./swarm-orchestration) | То же приложение проходит три стадии: сборка и запуск на одной машине, перенос в виртуальную машину, распределение по кластеру из трёх узлов | ![Docker Compose](https://img.shields.io/badge/Docker%20Compose-2496ED?style=flat-square&logo=docker&logoColor=white) ![Docker Swarm](https://img.shields.io/badge/Docker%20Swarm-2496ED?style=flat-square&logo=docker&logoColor=white) ![Vagrant](https://img.shields.io/badge/Vagrant-1868F2?style=flat-square&logo=vagrant&logoColor=white) |

## Автоматизация и доставка

| Проект | О чём | Технологии |
|---|---|---|
| [Ansible и Consul](./ansible-consul-iac) | Узлы настраиваются с управляющей машины ролями. Во второй части сервисы находят друг друга через service mesh, и адрес базы исчезает из конфигурации приложения | ![Ansible](https://img.shields.io/badge/Ansible-EE0000?style=flat-square&logo=ansible&logoColor=white) ![Consul](https://img.shields.io/badge/Consul-F24C53?style=flat-square&logo=consul&logoColor=white) ![Envoy](https://img.shields.io/badge/Envoy-AC6199?style=flat-square&logo=envoyproxy&logoColor=white) |
| [Конвейер GitLab CI/CD](./gitlab-cicd-pipeline) | Четыре стадии — стиль, сборка, тесты, доставка — с уведомлением в Telegram после каждой и выкладкой на сервер по кнопке | ![GitLab CI](https://img.shields.io/badge/GitLab%20CI-FC6D26?style=flat-square&logo=gitlab&logoColor=white) ![Bash](https://img.shields.io/badge/Bash-4EAA25?style=flat-square&logo=gnu-bash&logoColor=white) ![SSH](https://img.shields.io/badge/SSH-000000?style=flat-square) |

## Наблюдаемость

| Проект | О чём | Технологии |
|---|---|---|
| [Стек наблюдаемости](./observability-stack) | Кластер Swarm обвязывается метриками, логами и оповещениями: Prometheus собирает метрики, Loki — логи, Grafana сводит на дашборд, Alertmanager шлёт тревоги | ![Prometheus](https://img.shields.io/badge/Prometheus-E6522C?style=flat-square&logo=prometheus&logoColor=white) ![Loki](https://img.shields.io/badge/Loki-F46800?style=flat-square&logo=grafana&logoColor=white) ![Grafana](https://img.shields.io/badge/Grafana-F46800?style=flat-square&logo=grafana&logoColor=white) ![Alertmanager](https://img.shields.io/badge/Alertmanager-E6522C?style=flat-square&logo=prometheus&logoColor=white) |
| [Мониторинг в реальном времени](./log-analytics-monitoring) | Две стороны наблюдаемости сразу: скрипты создают и убирают нагрузку, генерируют и разбирают логи nginx, а стенд показывает, как эта нагрузка выглядит на графиках | ![Bash](https://img.shields.io/badge/Bash-4EAA25?style=flat-square&logo=gnu-bash&logoColor=white) ![Prometheus](https://img.shields.io/badge/Prometheus-E6522C?style=flat-square&logo=prometheus&logoColor=white) ![GoAccess](https://img.shields.io/badge/GoAccess-1E90FF?style=flat-square) |

## Основы: контейнеры, сети, Linux

| Проект | О чём | Технологии |
|---|---|---|
| [Свой образ Docker](./docker-nginx-fastcgi) | Путь от готового образа из реестра до собственного, разнесённого на два контейнера. Внутри — мини веб-сервер на C по протоколу FastCGI и закалка образа под непривилегированного пользователя | ![Docker](https://img.shields.io/badge/Docker-2496ED?style=flat-square&logo=docker&logoColor=white) ![NGINX](https://img.shields.io/badge/NGINX-009639?style=flat-square&logo=nginx&logoColor=white) ![FastCGI](https://img.shields.io/badge/FastCGI-A8B9CC?style=flat-square&logo=c&logoColor=black) ![Dockle](https://img.shields.io/badge/Dockle-0E7C7B?style=flat-square) |
| [Сети в Linux](./network-infrastructure) | Стенд из пяти машин: две подсети, два маршрутизатора. Статическая маршрутизация, сетевой экран, выдача адресов и трансляция во внешнюю сеть | ![Netplan](https://img.shields.io/badge/Netplan-E95420?style=flat-square&logo=ubuntu&logoColor=white) ![iptables](https://img.shields.io/badge/iptables-4D4D4D?style=flat-square&logo=linux&logoColor=white) ![isc-dhcp](https://img.shields.io/badge/isc--dhcp-4D4D4D?style=flat-square) |
| [Скрипты на Bash](./sys-monitor-scripts) | Пять скриптов: разбор аргументов, сбор сведений о машине, цветной вывод с настройкой из файла, обход файловой системы с построением дерева | ![Bash](https://img.shields.io/badge/Bash-4EAA25?style=flat-square&logo=gnu-bash&logoColor=white) ![find · awk · sed](https://img.shields.io/badge/find%20%C2%B7%20awk%20%C2%B7%20sed-4EAA25?style=flat-square) |
| [Установка Ubuntu Server](./linux-core-setup) | Первый проект траектории: развёртывание сервера с нуля и приведение в рабочее состояние — сеть, права, удалённый доступ, диагностика. Всё в консоли, без графики | ![Ubuntu Server](https://img.shields.io/badge/Ubuntu%20Server-E95420?style=flat-square&logo=ubuntu&logoColor=white) ![OpenSSH](https://img.shields.io/badge/OpenSSH-000000?style=flat-square) ![Netplan](https://img.shields.io/badge/Netplan-E95420?style=flat-square&logo=ubuntu&logoColor=white) |

---

## Сквозная линия: одно приложение, шесть способов доставки

Шесть проектов разворачивают **одно и то же приложение** — систему бронирования отелей из 7 микросервисов на Spring Boot с PostgreSQL и RabbitMQ. Меняется только способ доставки:

```
   Compose ──► Swarm ──► Ansible ──► манифесты K8s ──► k3s ──► Helm
   одна ВМ    кластер    роли и       Namespace…       свой     чарт и
              из 3       Consul       Deployment       кластер  Kustomize
```

Это даёт возможность сравнивать инструменты не по документации, а на одной и той же задаче: видно, что каждый следующий убирает, что добавляет и какой ценой. Наблюдения собраны в отчётах — например, чем `mode: global` отличается от `replicated` при том же наборе сервисов, и почему база в Kubernetes требует стратегии `Recreate`, а не `RollingUpdate`.

---

## Как устроен каждый проект

```
<проект>/
├── README.md         обзор, схема архитектуры, ключевые решения
├── main_report.md    подробный разбор с командами и скриншотами
├── images/           скриншоты работы
└── <код>             манифесты, скрипты, конфигурации, чарты
```

Публикуются только собственные наработки: скрипты, Dockerfile, docker-compose, роли Ansible, манифесты Kubernetes, Helm-чарты, конфигурации мониторинга. Учебные материалы, условия заданий и исходный код приложения выданы курсом и в репозиторий не входят — каждый README оговаривает это явно.

Пароли и ключи в манифестах — заглушки локальных стендов на виртуальных машинах, а не рабочие секреты.

---

Author: [Alexander Stepanovich](https://github.com/sher2yja)
