# DevOps-портфолио

Инженерные работы по траектории DevOps в Школе 21: от настройки голого Linux-сервера до Helm-релиза в кластере Kubernetes.

Через шесть проектов проходит **одно и то же приложение** — система бронирования отелей из 7 микросервисов на Spring Boot с PostgreSQL и RabbitMQ. Каждый раз оно разворачивается принципиально иначе: сначала Docker Compose, затем Swarm, потом Ansible, дальше сырые манифесты Kubernetes, собственный кластер k3s и, наконец, Helm-чарт. Это даёт возможность сравнивать инструменты не по документации, а на одной и той же задаче.

---

## Стек

![Linux](https://img.shields.io/badge/Linux-FCC624?style=flat-square&logo=linux&logoColor=black)
![Bash](https://img.shields.io/badge/Bash-4EAA25?style=flat-square&logo=gnu-bash&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-2496ED?style=flat-square&logo=docker&logoColor=white)
![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=flat-square&logo=kubernetes&logoColor=white)
![Helm](https://img.shields.io/badge/Helm-0F1689?style=flat-square&logo=helm&logoColor=white)
![Ansible](https://img.shields.io/badge/Ansible-EE0000?style=flat-square&logo=ansible&logoColor=white)
![Consul](https://img.shields.io/badge/Consul-F24C53?style=flat-square&logo=consul&logoColor=white)
![Prometheus](https://img.shields.io/badge/Prometheus-E6522C?style=flat-square&logo=prometheus&logoColor=white)
![Grafana](https://img.shields.io/badge/Grafana-F46800?style=flat-square&logo=grafana&logoColor=white)
![GitLab CI](https://img.shields.io/badge/GitLab%20CI-FC6D26?style=flat-square&logo=gitlab&logoColor=white)
![Vagrant](https://img.shields.io/badge/Vagrant-1868F2?style=flat-square&logo=vagrant&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-4169E1?style=flat-square&logo=postgresql&logoColor=white)
![NGINX](https://img.shields.io/badge/NGINX-009639?style=flat-square&logo=nginx&logoColor=white)

---

## Проекты

### Kubernetes и оркестрация

| Проект | О чём | Технологии |
|---|---|---|
| [Helm и Kustomize](./devops_projects/helm-kustomize-deploy) | Доставка приложения двумя способами; передача работающих объектов под управление Helm без простоя | Helm, Kustomize, k3s |

### Инфраструктура и автоматизация

*Раздел наполняется.*

### Основы: Linux, сети, скрипты

*Раздел наполняется.*

### Базы данных

*Раздел наполняется.*

---

## Как устроен каждый проект

```
<проект>/
├── README.md         обзор, стек, схема архитектуры, ключевые решения
├── main_report.md    подробный разбор с командами и скриншотами
├── img/              скриншоты работы
└── <код>             манифесты, скрипты, конфигурации, чарты
```

В репозитории лежат **собственные наработки**: скрипты, Dockerfile, docker-compose, роли Ansible, манифесты Kubernetes, Helm-чарты, конфигурации мониторинга. Учебные материалы и условия заданий, выданные Школой 21, не публикуются.

Пароли и ключи в манифестах — заглушки для локальных стендов на виртуальных машинах, а не рабочие секреты.

---

Author: [Alexander Stepanovich](https://github.com/sher2yja)
