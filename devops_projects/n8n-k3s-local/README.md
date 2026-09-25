# 🚢 n8n в локальном кластере k3s

### 📌 Обзор проекта

Локальный стенд n8n в режиме очередей: отдельные main, webhook и worker, PostgreSQL и Redis. Виртуальная машина создаётся Vagrant, настраивается Ansible, приложение разворачивается манифестами Kubernetes или собственным Helm-чартом. В проекте также проверены мониторинг, обновление и откат релиза, резервное копирование и восстановление сохранённых credentials.

Стенд работает **только на локальных VM**. VPS и публичный HTTPS не планируются. Отдельная runner-VM подготовлена для GitHub Actions, но CI/CD ещё не запускался: пользователь пока не отправил проект в GitHub. Production-развёртывание не подтверждено. Встроенный интерфейс n8n служит фронтендом проекта.

### 🛠 Стек технологий

Vagrant · libvirt · Ubuntu 24.04 · Ansible · k3s · Kubernetes · Helm · Docker · n8n · PostgreSQL · Redis · Prometheus · Grafana · Bash

### 🏗 Архитектура

```text
Vagrant → Ubuntu VM → Ansible → k3s
                              ├── n8n main ─────┐
                              ├── n8n webhook ──┼── PostgreSQL
                              └── n8n worker ───┴── Redis (очередь)
                                     │
                         Prometheus → Grafana
```

Секреты создаются локально из `.env` и не входят в репозиторий. Для восстановления credentials нужны **и дамп базы, и исходный ключ шифрования**. Резервные копии остаются на той же машине: независимое хранилище здесь не проверено.

Собственный `Dockerfile` можно проверить без Docker Hub: после установки Helm выполните `docker build -t do14-n8n:local .`, затем `docker save do14-n8n:local | vagrant ssh -c 'sudo k3s ctr images import -'` и обновите релиз с `--set n8n.image=do14-n8n --set n8n.imageTag=local`. Полные команды — в [отчёте](main_report.md#2-режим-очередей-и-kubernetes). Тег `local` живёт только на этой VM; при пересоздании его импортируют снова. [GitHub Actions](../../.github/workflows/do14-n8n.yml) будет публиковать образ в GHCR и автоматически обновлять локальный staging через отдельную runner-VM после пуша. Docker Hub не нужен.

### 📂 Что в папке

| Путь | Назначение |
|---|---|
| `Vagrantfile`, `ansible/`, `runner/` | VM приложения, идемпотентная установка k3s и отдельная runner-VM |
| `Dockerfile`, `experiments/` | собственный образ и два Compose-эксперимента |
| `k8s/base/`, `chart/` | манифесты и Helm-чарт |
| `monitoring/` | локальные Prometheus и Grafana |
| `scripts/` | развёртывание, резервирование и восстановление |
| `workflows/` | тесты очереди и сохранённого PostgreSQL credential |
| `docs/` | контракт и операционные инструкции |
| [main_report.md](main_report.md) | выполненные проверки, ограничения и воспроизведение |

### 📈 Итоговый результат

На локальной VM проверены повторный Ansible-прогон без изменений, работа трёх ролей n8n, Helm upgrade и rollback, сбор метрик, а также восстановление базы и ключа шифрования в новом namespace. После восстановления workflow вновь выполнил `SELECT 1 AS credential_ok` и вернул `{"credential_ok":1}`. Подробные факты и команды — в [отчёте](main_report.md).
