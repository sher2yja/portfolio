# 🚢 n8n в локальном кластере k3s

### 📌 Обзор проекта

Локальный стенд n8n в режиме очередей: отдельные main, webhook и worker, PostgreSQL и Redis. Виртуальная машина создаётся Vagrant, настраивается Ansible; отдельный host-playbook Ansible подключает мониторинг и команды ручного резервного копирования после создания окружений. Приложение разворачивается манифестами Kubernetes или собственным Helm-чартом через GitHub Actions. В проекте также проверены мониторинг, обновление и откат релиза, резервное копирование и восстановление сохранённых credentials.

Стенд работает **только на локальных VM**. VPS и публичный HTTPS не планируются. GitHub Actions выполнил build → test → автоматический staging и ручной production через отдельную runner-VM. Встроенный интерфейс n8n служит фронтендом проекта.

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

Для staging и production созданы разные секреты из `.env` и `.env.production`; в репозиторий они не входят. Для восстановления credentials нужны **и дамп базы, и исходный ключ шифрования**. Production-копия сохраняется вручную в закрытый каталог хостового ПК вне VM и Git; скрипт оставляет последние 14 проверенных копий. Ручная проверка восстанавливает последнюю копию во временном PostgreSQL и проверяет таблицы и credentials. Отдельный снимок production-копии зашифрован GPG и проверен расшифровкой и SHA-256 на USB-носителе. По решению владельца все таймеры удалены после успешного разового опыта: **новые копии и проверки больше не запускаются автоматически**.

После настройки VM, обоих namespace и локальных Secret запустите на хосте `ansible-playbook -i localhost, ansible/host.yml`. Он подключает ручные backup-сервисы и мониторинг, но не таймеры; приложение по-прежнему доставляет GitHub Actions. Для ручной копии и проверки выполните `systemctl --user start do14-backup.service`, затем `systemctl --user start do14-backup-verify.service`. При повторном прогоне host-playbook должен показать `changed=0`.

Собственный `Dockerfile` можно проверить без публикации образа: после установки Helm выполните `docker build -t do14-n8n:local .`, затем `docker save do14-n8n:local | vagrant ssh -c 'sudo k3s ctr images import -'` и обновите релиз с `--set n8n.image=do14-n8n --set n8n.imageTag=local`. Полные команды — в [отчёте](main_report.md#2-режим-очередей-и-kubernetes). Тег `local` живёт только на этой VM; при пересоздании его импортируют снова. [GitHub Actions](../../.github/workflows/do14-n8n.yml) публикует собственный образ в GHCR и автоматически обновляет локальный staging. Docker Hub используется только для базового образа.

### 📂 Что в папке

| Путь | Назначение |
|---|---|
| `Vagrantfile`, `ansible/`, `runner/` | VM приложения, идемпотентная установка k3s и отдельная runner-VM |
| `Dockerfile`, `experiments/` | собственный образ и два Compose-эксперимента |
| `k8s/base/`, `chart/` | манифесты и Helm-чарт |
| `monitoring/` | локальные Prometheus и Grafana: очередь, p95 исполнений, доля ошибок, базы, Pod и диск; метрики на PVC |
| `scripts/`, `systemd/` | развёртывание, ручное резервирование и восстановление |
| `workflows/` | smoke-, нагрузочный и Telegram-сценарии, сводка кластера и наблюдение за CI |
| `docs/` | контракт и операционные инструкции |
| [main_report.md](main_report.md) | выполненные проверки, ограничения и воспроизведение |

### 📈 Итоговый результат

На локальной VM проверены повторный Ansible-прогон без изменений, работа трёх ролей n8n, Helm upgrade и rollback, сбор метрик, срабатывание алерта и очередь из 50 заданий, автоматический staging и ручной production через GitHub Actions. Staging сохранил credential после обновления (`{"credential_ok":1}`); production-дамп и ключ восстановлены в отдельном namespace с тем же образом. Из свежего публичного клона создана отдельная VM, где Helm установил готовый стенд в пустой namespace. Production n8n отправил красное Telegram-уведомление о сбое staging и зелёное о восстановлении без повторов в промежуточных циклах. Токен и chat ID задаются только внутри n8n; использованный для опыта токен владелец отзовёт после завершения проекта. Подробные факты и команды — в [отчёте](main_report.md).
