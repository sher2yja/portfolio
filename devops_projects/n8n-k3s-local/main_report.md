# n8n в локальном кластере k3s: отчёт

## Границы работы

Это воспроизводимый локальный стенд на VM приложения и отдельной runner-VM, а не публичный сервис. Он демонстрирует путь от подготовки кластера до восстановления workflow с сохранённым доступом к PostgreSQL. GitHub Actions согласован вместо GitLab CI; build, test, автоматический staging и ручной production проверены.

## 1. Подготовка стенда

`Vagrantfile` создаёт Ubuntu 24.04 с 4 vCPU и 6 ГБ RAM для двух окружений. `ansible/site.yml` устанавливает k3s `v1.35.8+k3s1` и отключает встроенный Traefik. Повторный `vagrant provision`, запущенный из этой папки портфолио на существующей VM, завершился с `changed=0` (7 задач `ok`, 2 пропущены). Затем из этой же папки создана **новая** VM: Ansible выполнил 9 задач без ошибок, узел k3s перешёл в `Ready`. Начальная конфигурация была 2 vCPU/4 ГБ; после добавления production лимиты увеличены без замены диска VM.

```bash
bash scripts/init-local-env.sh
vagrant up --provider=libvirt
vagrant provision
vagrant ssh -c 'sudo k3s kubectl get nodes'
```

Скрипт инициализации создаёт `.env` с ограниченными правами и не перезаписывает существующий. Значения секретов в публикацию не входят.

## 2. Режим очередей и Kubernetes

В `experiments/` опробованы одиночный n8n и queue-mode Compose. Для k3s отдельно подготовлены обычные манифесты и Helm-чарт. Main обслуживает редактор, webhook принимает вызовы, worker выполняет задания; PostgreSQL хранит состояние, Redis обеспечивает очередь. Встроенный редактор n8n — интерфейс пользователя, отдельный frontend не нужен.

```bash
bash scripts/deploy-local-k8s.sh
bash scripts/vm-kubectl.sh -n do14 get pods
bash scripts/deploy-local-helm.sh
bash scripts/vm-kubectl.sh -n do14-helm get pods
```

Обе установки проверены на локальной VM. Дополнительно Helm развёрнут на новой VM из этой папки: main, webhook, worker, PostgreSQL и Redis стали `Running`, сервис main ответил `{"status":"ok"}` на `/healthz`. Чарт требует уже существующий Kubernetes Secret и не создаёт его из шаблона. Подробный контракт перечислен в [docs/contract.md](docs/contract.md).

Собственный `Dockerfile` собран локально с тегом `do14-n8n:portfolio-verify`. Образ передан в containerd VM через `docker save | vagrant ssh -c 'sudo k3s ctr images import -'`, без Docker Hub и другого внешнего реестра. Helm upgrade переключил все три роли на этот тег; все Deployment стали доступны, `/healthz` снова ответил `{"status":"ok"}`, а диагностическая команда образа подтвердила доступность сервиса. Для повторения опыта с локальным тегом:

```bash
docker build -t do14-n8n:local .
set -o pipefail
docker save do14-n8n:local | vagrant ssh -c 'sudo k3s ctr images import -'
bash scripts/vm-kubectl.sh -- helm upgrade do14 chart \
  --namespace do14-helm -f chart/values-staging.yaml \
  --set existingSecret=n8n-secrets \
  --set n8n.image=do14-n8n --set n8n.imageTag=local \
  --wait --timeout 10m
```

Этот опыт проверил локальную доставку собственного образа. Позднее GitHub Actions опубликовал образ в GHCR и автоматически развернул его в staging; результаты приведены ниже.

## 3. Обновление и откат

Чистая Helm-установка подняла main, webhook, worker, PostgreSQL и Redis. Два обычных обновления прошли с `--wait`. Затем был намеренно указан отсутствующий тег образа: роли n8n получили `ErrImagePull`, а PostgreSQL и Redis остались запущены. `helm rollback --wait` вернул работающее приложение. Опыт повторён после создания credential; тестовый workflow после отката снова вернул `{"credential_ok":1}`.

## 4. Мониторинг

Prometheus собирал метрики main и webhook: обе цели отображались как `up`. Проверено наличие метрик очереди, в том числе `n8n_scaling_mode_queue_jobs_waiting` и `n8n_scaling_mode_queue_jobs_active`. Grafana загрузила локальный дашборд. Хранилище мониторинга — `emptyDir`; долговременное хранение и реакция алертов не испытывались.

```bash
bash scripts/vm-kubectl.sh apply -f monitoring/local.yaml
bash scripts/vm-kubectl.sh -n do14-monitoring port-forward service/grafana 3000:3000
```

## 5. Резервная копия и восстановление

`scripts/backup-local.sh` сохраняет дамп PostgreSQL, фактически применённые Helm values с SHA образа и выбранный `.env` с ключом шифрования; контрольные суммы позволяют выявить повреждение файлов. `scripts/restore-local.sh` принимает новый namespace и не перезаписывает исходный. В тесте staging дамп и ключ восстановлены в `do14-restore-credential`; workflow с PostgreSQL credential после этого выполнил `SELECT 1 AS credential_ok` и вернул `{"credential_ok":1}`. Это проверяет пригодность сохранённого доступа, а не только наличие таблиц.

```bash
bash scripts/backup-local.sh
bash scripts/restore-local.sh backups/<имя-копии> do14-restore-test
bash scripts/backup-local.sh backups/production-copy do14-production .env.production
bash scripts/restore-local.sh backups/production-copy do14-production-restore
```

Локальная копия на том же компьютере не защищает от его потери. Независимый носитель и восстановление после удаления всего стенда остаются отдельными непроведёнными проверками.

## 6. Локальный runner и границы проверки

Создана отдельная Ubuntu VM `do14-runner` (2 vCPU, 2 ГБ RAM), без Vagrant shared folder. GitHub API показывает runner `online` с label `do14-deploy`. Внутри VM `kubectl auth can-i` вернул `yes` для Deployment в `do14-helm` и `do14-production`, `no` для Secrets в `kube-system` и создания Namespace.

Реальный workflow [do14-n8n](../../.github/workflows/do14-n8n.yml) на коммите `7066ec56` собрал образ из базового `docker.io/n8nio/n8n:2.40.6`, опубликовал его в GHCR и проверил чарт. Первый staging-job упал, потому что ограниченной роли не хватало чтения ReplicaSet; рабочая ревизия 10 восстановлена, затем добавлены только `get/list/watch` для ReplicaSet в обоих namespace. Повторный staging-job [завершился успешно](https://github.com/sher2yja/portfolio/actions/runs/36134534960), все пять Pod стали `Running`, три роли n8n перешли на `ghcr.io/sher2yja/do14-n8n:7066ec56f9dcf0cbeb84fa78e4494341b12cf1d3`. После деплоя `/healthz` вернул `{"status":"ok"}`, а тестовый workflow с сохранённым доступом — `{"credential_ok":1}`. Кластер скачал пакет GHCR без pull-secret; ручная смена видимости не потребовалась.

Первый production-job был отменён из-за `Insufficient memory`: VM расширена с 4 до 6 ГБ RAM и с 2 до 4 vCPU. После остановки старого тестового namespace нагрузка стабилизировалась. Повторный [production workflow](https://github.com/sher2yja/portfolio/actions/runs/36136805996) установил отдельный Helm-релиз `do14` в `do14-production`; все пять Pod стали готовы, `/healthz` ответил `{"status":"ok"}`, staging остался доступен. Production использует отдельные Secret и PVC. Его дамп, ключ и реальные Helm values сохранены с контрольными суммами, восстановлены в `do14-production-restore` и дали 142 таблицы, тот же ключ и SHA образа, все пять Pod `Running` и ответ `/healthz`. Тестовый namespace после проверки масштабирован до нуля, PVC и Secret сохранены.

## 7. Что не проверено

- VPS, публичный DNS, TLS и внешние webhook-вызовы;
- отказ worker или Redis под нагрузкой и реакция алертов;
- полное развёртывание из свежего **публичного Git-клона**: новая VM из локальной папки портфолио и автоматический деплой из GitHub проверены по отдельности, единый прогон с нуля — нет.

Команды диагностики и подробная хронология экспериментов приведены в [docs/runbook.md](docs/runbook.md). В опубликованные файлы не включены `.env`, дампы, `.vagrant/`, приватные ключи и kubeconfig.
