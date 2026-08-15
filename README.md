# Портфолио: DevOps и базы данных

Собственные инженерные проекты по направлению DevOps: от настройки голого Linux-сервера до Helm-релиза в кластере Kubernetes. Плюс раздел с SQL.

Через шесть проектов проходит **одно и то же приложение** — система бронирования отелей из 7 микросервисов на Spring Boot с PostgreSQL и RabbitMQ. Каждый раз оно разворачивается принципиально иначе: сначала Docker Compose, затем Swarm, потом Ansible, дальше сырые манифесты Kubernetes, собственный кластер k3s и, наконец, Helm-чарт. Это даёт возможность сравнивать инструменты не по документации, а на одной и той же задаче.

---

## Стек

| | |
|---|---|
| **Оркестрация и контейнеры** | ![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=flat-square&logo=kubernetes&logoColor=white) ![Helm](https://img.shields.io/badge/Helm-0F1689?style=flat-square&logo=helm&logoColor=white) ![Kustomize](https://img.shields.io/badge/Kustomize-326CE5?style=flat-square&logo=kubernetes&logoColor=white) ![k3s](https://img.shields.io/badge/k3s-FFC61C?style=flat-square&logo=k3s&logoColor=black) ![Docker](https://img.shields.io/badge/Docker-2496ED?style=flat-square&logo=docker&logoColor=white) ![Vagrant](https://img.shields.io/badge/Vagrant-1868F2?style=flat-square&logo=vagrant&logoColor=white) |
| **Автоматизация и доставка** | ![Ansible](https://img.shields.io/badge/Ansible-EE0000?style=flat-square&logo=ansible&logoColor=white) ![Consul](https://img.shields.io/badge/Consul-F24C53?style=flat-square&logo=consul&logoColor=white) ![Envoy](https://img.shields.io/badge/Envoy-AC6199?style=flat-square&logo=envoyproxy&logoColor=white) ![GitLab CI](https://img.shields.io/badge/GitLab%20CI-FC6D26?style=flat-square&logo=gitlab&logoColor=white) |
| **Наблюдаемость** | ![Prometheus](https://img.shields.io/badge/Prometheus-E6522C?style=flat-square&logo=prometheus&logoColor=white) ![Grafana](https://img.shields.io/badge/Grafana-F46800?style=flat-square&logo=grafana&logoColor=white) ![Loki](https://img.shields.io/badge/Loki-F46800?style=flat-square&logo=grafana&logoColor=white) ![Alertmanager](https://img.shields.io/badge/Alertmanager-E6522C?style=flat-square&logo=prometheus&logoColor=white) |
| **Системы и данные** | ![Linux](https://img.shields.io/badge/Linux-FCC624?style=flat-square&logo=linux&logoColor=black) ![Bash](https://img.shields.io/badge/Bash-4EAA25?style=flat-square&logo=gnu-bash&logoColor=white) ![NGINX](https://img.shields.io/badge/NGINX-009639?style=flat-square&logo=nginx&logoColor=white) ![PostgreSQL](https://img.shields.io/badge/PostgreSQL-4169E1?style=flat-square&logo=postgresql&logoColor=white) ![ANSI SQL](https://img.shields.io/badge/ANSI%20SQL-336791?style=flat-square) |

---

## Проекты

Тринадцать проектов, порядок — от сложного к базовому. Подробности разделов: [DevOps и инфраструктура](./devops_projects) · [Работа с базами данных](./sql_projects).

### Kubernetes и оркестрация

| Проект | О чём | Технологии |
|---|---|---|
| [Helm и Kustomize](./devops_projects/helm-kustomize-deploy) | Доставка приложения двумя способами; передача работающих объектов под управление Helm без простоя | ![Helm](https://img.shields.io/badge/Helm-0F1689?style=flat-square&logo=helm&logoColor=white) ![Kustomize](https://img.shields.io/badge/Kustomize-326CE5?style=flat-square&logo=kubernetes&logoColor=white) ![k3s](https://img.shields.io/badge/k3s-FFC61C?style=flat-square&logo=k3s&logoColor=black) ![Vagrant](https://img.shields.io/badge/Vagrant-1868F2?style=flat-square&logo=vagrant&logoColor=white) |
| [Кластер k3s с TLS](./devops_projects/k3s-cluster-tls) | Кластер с нуля на трёх машинах: замена Ingress на NGINX, wildcard-сертификат, постоянное хранилище | ![k3s](https://img.shields.io/badge/k3s-FFC61C?style=flat-square&logo=k3s&logoColor=black) ![NGINX](https://img.shields.io/badge/NGINX-009639?style=flat-square&logo=nginx&logoColor=white) ![cert-manager](https://img.shields.io/badge/cert--manager-326CE5?style=flat-square) |
| [Микросервисы в Kubernetes](./devops_projects/k8s-microservices) | Приложение из 7 микросервисов в собственных манифестах — от `Namespace` до `Deployment` | ![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=flat-square&logo=kubernetes&logoColor=white) ![minikube](https://img.shields.io/badge/minikube-326CE5?style=flat-square&logo=kubernetes&logoColor=white) ![kubectl](https://img.shields.io/badge/kubectl-326CE5?style=flat-square&logo=kubernetes&logoColor=white) |
| [Compose и Swarm](./devops_projects/swarm-orchestration) | То же приложение: одна машина, затем виртуальная, затем кластер из трёх узлов | ![Docker Compose](https://img.shields.io/badge/Docker%20Compose-2496ED?style=flat-square&logo=docker&logoColor=white) ![Docker Swarm](https://img.shields.io/badge/Docker%20Swarm-2496ED?style=flat-square&logo=docker&logoColor=white) ![Vagrant](https://img.shields.io/badge/Vagrant-1868F2?style=flat-square&logo=vagrant&logoColor=white) |

### Автоматизация и доставка

| Проект | О чём | Технологии |
|---|---|---|
| [Ansible и Consul](./devops_projects/ansible-consul-iac) | Конфигурирование узлов ролями; service mesh, после которого адрес базы исчезает из конфигурации приложения | ![Ansible](https://img.shields.io/badge/Ansible-EE0000?style=flat-square&logo=ansible&logoColor=white) ![Consul](https://img.shields.io/badge/Consul-F24C53?style=flat-square&logo=consul&logoColor=white) ![Envoy](https://img.shields.io/badge/Envoy-AC6199?style=flat-square&logo=envoyproxy&logoColor=white) |
| [Конвейер GitLab CI/CD](./devops_projects/gitlab-cicd-pipeline) | Стиль, сборка, тесты, доставка — с уведомлением в Telegram после каждой стадии | ![GitLab CI](https://img.shields.io/badge/GitLab%20CI-FC6D26?style=flat-square&logo=gitlab&logoColor=white) ![Bash](https://img.shields.io/badge/Bash-4EAA25?style=flat-square&logo=gnu-bash&logoColor=white) ![SSH](https://img.shields.io/badge/SSH-000000?style=flat-square) |

### Наблюдаемость

| Проект | О чём | Технологии |
|---|---|---|
| [Стек наблюдаемости](./devops_projects/observability-stack) | Метрики, логи и оповещения для кластера Swarm на одном дашборде | ![Prometheus](https://img.shields.io/badge/Prometheus-E6522C?style=flat-square&logo=prometheus&logoColor=white) ![Loki](https://img.shields.io/badge/Loki-F46800?style=flat-square&logo=grafana&logoColor=white) ![Grafana](https://img.shields.io/badge/Grafana-F46800?style=flat-square&logo=grafana&logoColor=white) ![Alertmanager](https://img.shields.io/badge/Alertmanager-E6522C?style=flat-square&logo=prometheus&logoColor=white) |
| [Мониторинг в реальном времени](./devops_projects/log-analytics-monitoring) | Скрипты создают нагрузку и разбирают логи, стенд показывает её на графиках | ![Bash](https://img.shields.io/badge/Bash-4EAA25?style=flat-square&logo=gnu-bash&logoColor=white) ![Prometheus](https://img.shields.io/badge/Prometheus-E6522C?style=flat-square&logo=prometheus&logoColor=white) ![GoAccess](https://img.shields.io/badge/GoAccess-1E90FF?style=flat-square) |

### Основы: контейнеры, сети, Linux

| Проект | О чём | Технологии |
|---|---|---|
| [Свой образ Docker](./devops_projects/docker-nginx-fastcgi) | От готового образа к собственному: веб-сервер на C по FastCGI и закалка образа | ![Docker](https://img.shields.io/badge/Docker-2496ED?style=flat-square&logo=docker&logoColor=white) ![NGINX](https://img.shields.io/badge/NGINX-009639?style=flat-square&logo=nginx&logoColor=white) ![FastCGI](https://img.shields.io/badge/FastCGI-A8B9CC?style=flat-square&logo=c&logoColor=black) ![Dockle](https://img.shields.io/badge/Dockle-0E7C7B?style=flat-square) |
| [Сети в Linux](./devops_projects/network-infrastructure) | Пять машин, две подсети: маршрутизация, сетевой экран, выдача адресов, NAT | ![Netplan](https://img.shields.io/badge/Netplan-E95420?style=flat-square&logo=ubuntu&logoColor=white) ![iptables](https://img.shields.io/badge/iptables-4D4D4D?style=flat-square&logo=linux&logoColor=white) ![isc-dhcp](https://img.shields.io/badge/isc--dhcp-4D4D4D?style=flat-square) |
| [Скрипты на Bash](./devops_projects/sys-monitor-scripts) | Разбор аргументов, сбор сведений о машине, цветной вывод, обход файловой системы | ![Bash](https://img.shields.io/badge/Bash-4EAA25?style=flat-square&logo=gnu-bash&logoColor=white) ![find · awk · sed](https://img.shields.io/badge/find%20%C2%B7%20awk%20%C2%B7%20sed-4EAA25?style=flat-square) |
| [Установка Ubuntu Server](./devops_projects/linux-core-setup) | Сервер с нуля в консоли: сеть, права, удалённый доступ, диагностика | ![Ubuntu Server](https://img.shields.io/badge/Ubuntu%20Server-E95420?style=flat-square&logo=ubuntu&logoColor=white) ![OpenSSH](https://img.shields.io/badge/OpenSSH-000000?style=flat-square) ![Netplan](https://img.shields.io/badge/Netplan-E95420?style=flat-square&logo=ubuntu&logoColor=white) |

### Базы данных

| Проект | О чём | Технологии |
|---|---|---|
| [Выборки по базе пиццерий](./sql_projects/pizzeria-sql-basics) | Десять запросов к пяти связанным таблицам. Часть запросов обходится без `JOIN` и `IN`: таблицы связываются подзапросами вручную | ![PostgreSQL](https://img.shields.io/badge/PostgreSQL-4169E1?style=flat-square&logo=postgresql&logoColor=white) ![ANSI SQL](https://img.shields.io/badge/ANSI%20SQL-336791?style=flat-square) ![Bash](https://img.shields.io/badge/Bash-4EAA25?style=flat-square&logo=gnu-bash&logoColor=white) |

---

## Как устроен каждый проект

```
<проект>/
├── README.md         обзор, стек, схема архитектуры, ключевые решения
├── main_report.md    подробный разбор с командами и скриншотами
├── images/           скриншоты работы
└── <код>             манифесты, скрипты, конфигурации, чарты
```

В репозитории лежат **собственные наработки**: скрипты, Dockerfile, docker-compose, роли Ansible, манифесты Kubernetes, Helm-чарты, конфигурации мониторинга, SQL-запросы. Сторонние материалы и исходный код разворачиваемого приложения в репозиторий не входят.

Пароли и ключи в манифестах — заглушки для локальных стендов на виртуальных машинах, а не рабочие секреты.

---

Author: [Alexander Stepanovich](https://github.com/sher2yja)
