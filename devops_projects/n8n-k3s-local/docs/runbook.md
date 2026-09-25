# Runbook локального стенда

## Проверенный путь

```bash
bash scripts/init-local-env.sh
vagrant up --provider=libvirt
vagrant provision
bash scripts/deploy-local-k8s.sh
bash scripts/deploy-local-helm.sh
bash scripts/vm-kubectl.sh -n do14-helm get pods
```

VM использует libvirt, Ubuntu 24.04 и k3s `v1.35.8+k3s1`. Повторный Ansible-прогон на проверенном стенде завершился с `changed=0`. Из свежего публичного Git-клона коммита `5c99ee6` создана отдельная VM с 4 vCPU/6 ГБ; Ansible установил k3s, Helm поднял пять компонентов в пустом namespace, `/healthz` ответил `{"status":"ok"}`. Повторный `vagrant provision` дал `changed=0`. Временная VM удалена, исходная возвращена в работу. Отдельно собственный образ импортирован в k3s без внешнего реестра и применён ко всем трём ролям n8n; GitHub Actions позже доставил образ через GHCR.

## Helm: обновление и откат

Чистая установка в `do14-helm` дала три роли n8n, PostgreSQL и Redis в состоянии Running. Два первых `helm upgrade --wait` повысили ревизию до 3 без ошибки. После создания владельца и credential ещё два обновления повысили ревизию до 8; workflow `DO14 credential restore smoke` после них ответил `{"credential_ok":1}`.

Для контролируемой проверки отката ревизия 4 получила несуществующий тег `do14-intentionally-missing`. Main, webhook и worker перешли в `ErrImagePull`, а PostgreSQL и Redis остались Running. `helm rollback do14 3 --wait` создал рабочую ревизию 5. Позже опыт повторён уже с credential: ревизия 9 получила несуществующий `n8n.imageTag`, webhook перешёл в `ErrImagePull`; `helm rollback do14 8 --wait` восстановил сервис. После отката credential-workflow снова ответил `{"credential_ok":1}`.

## Диагностика

```bash
bash scripts/vm-kubectl.sh -n do14-helm get pods
bash scripts/vm-kubectl.sh -n do14-helm describe pod -l app.kubernetes.io/component=worker
bash scripts/vm-kubectl.sh -n do14-helm logs deployment/do14-worker -c n8n
bash scripts/vm-kubectl.sh -- helm -n do14-helm history do14
journalctl --user -u do14-backup.service -u do14-backup-verify.service --since today
```

Если `ImagePullBackOff`, проверьте тег и права registry. Если main или worker не стартует, проверьте PostgreSQL, Redis, одинаковый `N8N_ENCRYPTION_KEY` и токен runner. Секреты в команды диагностики и отчёт не копируйте.

Для сравнения ролей используйте `logs deployment/do14-main --since=15m`, `logs deployment/do14-webhook --since=15m` и `logs deployment/do14-worker -c n8n --since=15m`; для production замените namespace на `do14-production`. Логи доступны через штатный Kubernetes API и остаются локальными; отдельное централизованное хранилище логов не разворачивалось. Не копируйте в публичный отчёт строки с данными исполнений или секретами.

## Мониторинг и восстановление

После включения метрик main вернул `n8n_scaling_mode_queue_jobs_waiting 0` и `n8n_scaling_mode_queue_jobs_active 0`. Prometheus показал targets `n8n-main` и `n8n-webhook` в состоянии `up`, Grafana API нашёл дашборд `DO14 — n8n queue`. Позже добавлены отдельные PostgreSQL exporters для staging и production: оба отдали `pg_up=1`, а `pg_database_size_bytes{datname="n8n"}` вернула 16 723 091 и 16 493 715 байт соответственно. Восемь правил проверены `promtool check rules`. При масштабировании staging main до нуля `N8nMainUnavailable` перешёл в `pending`, затем `firing`; после восстановления main алерт исчез, а `/healthz` вновь ответил `{"status":"ok"}`. Production оставался работоспособен. Доставка уведомлений и нагрузка проверены отдельными опытами ниже.

В production n8n работает `DO14 Telegram alerts`. Владелец задал chat ID и Telegram credential только в интерфейсе; токен и ID не находятся в JSON или Git. Для воспроизведения создайте отдельное состояние алертов и PostgreSQL credential, затем импортируйте `workflows/telegram-alerts.json` с подстановкой Telegram credential и chat ID внутри n8n:

```bash
bash scripts/vm-kubectl.sh -n do14-production exec -i do14-postgres-0 -- \
  psql -v ON_ERROR_STOP=1 -U n8n -d n8n < monitoring/alert-state.sql
bash scripts/import-local-postgres-credential.sh \
  do14-production .env.production DO14ProductionPgCredential 'DO14 production PostgreSQL'
```

Первый вариант workflow использовал static data. При одном `firing` два соседних запуска отправили два одинаковых сообщения; поэтому он заменён атомарным переходом состояния в PostgreSQL. SQL-транзакция с откатом дала одну строку для нового алерта, ноль для повтора и одну для снятия. В повторном опыте staging main был остановлен: Prometheus перешёл в `firing`, Telegram прислал одно красное сообщение; два последующих запуска Telegram-узел не вызывали. После восстановления main и `/healthz` пришло одно зелёное сообщение; в таблице `do14_ops.alert_state` состояние стало `firing=false`. Staging и production main вернулись к 1/1. Токен, временно использованный при этой проверке, нужно отозвать и заменить в Telegram credential, затем проверить отправку повторно.

`workflows/cluster-summary.json` и `workflows/ci-failure-watch.json` импортированы в production неактивными. В интерфейсе n8n откройте каждый workflow, выберите существующий Telegram credential в последнем узле и замените `SET_CHAT_ID_IN_N8N` на числовой ID чата; проверьте часовой пояс расписания сводки (09:00), выполните ручной тест и только затем активируйте. Сводка показывает перезапуски Pod за последние 24 часа, неготовые Pod и занятость диска. CI-наблюдатель при первом штатном запуске запоминает существующие ошибки без отправки старых уведомлений; после новой неуспешной GitHub Actions run отправляет ссылку. Токен и chat ID не вписывайте в файлы репозитория.

Для опыта с очередью в staging импортирован и опубликован `workflows/queue-load.json`: каждый вызов webhook выполняет задачу на worker (по умолчанию 3 секунды, тестовый `delayMs` ограничен 30 секундами). Один пробный запрос и затем 50 параллельных запросов вернули HTTP 200. Во время серии метрики main показали 15 ожидающих и 5 активных заданий, после серии — 0 и 0; счётчик завершённых заданий после рестарта main достиг 51, ошибок — 0. Это подтверждает рост и рассасывание очереди, но не проверяет автоматическое масштабирование.

Отказ worker проверен отдельно. Мягкое удаление Pod во время серии из десяти 15-секундных задач не прервало их: все запросы вернули HTTP 200. Затем при `active=1` единственный worker Pod удалён принудительно (`--grace-period=0 --force`) во время 30-секундной задачи. Deployment создал новый Pod, но исходный webhook вернул HTTP 500 через 102 секунды; execution 170 получил статус `error` с сообщением о превышении числа попыток обработки, счётчик `n8n_scaling_mode_queue_jobs_failed` вырос до 1. Алерт `N8nExecutionFailures` доставил красное Telegram-сообщение. Последующий 3-секундный запрос вернул HTTP 200, worker готов, очередь снова `waiting=0, active=0`. Автоматическое успешное повторение прерванного задания **не подтверждено**.

`scripts/backup-local.sh` создал дамп, копию `.env` и values-файл, все с контрольными суммами. Первый `scripts/restore-local.sh` развернул их в новом `do14-restore-test` namespace: сначала приложение было масштабировано до нуля, после импорта дампа запущено; Helm завершился успешно. Исходная и восстановленная БД содержали по 142 публичные таблицы. Это был только тест механики.

После настройки владельца импортированы два workflow. `DO14 queue smoke` выполнился в основном namespace с ответом HTTP 200; worker зафиксировал execution 1. Копия с ним была восстановлена в `do14-restore-workflow`, где тот же webhook ответил HTTP 200, а worker завершил execution 2.

Для полного критерия `scripts/import-local-postgres-credential.sh` создал локальный PostgreSQL credential, не печатая пароль. Workflow `DO14 credential restore smoke` выполнил `SELECT 1 AS credential_ok` через этот credential и вернул `{"credential_ok":1}`. Бэкап `backups/20260925T112004Z` восстановлен в пустом `do14-restore-credential`; тот же webhook там снова вернул `{"credential_ok":1}`, а worker завершил execution 3. Это подтверждает совместное восстановление дампа и ключа шифрования, а не только наличие таблиц.

Контролируемый отказ staging PostgreSQL: StatefulSet временно масштабирован с 1 до 0. Метрика `pg_up{job="postgres"}` стала 0, правила `PostgresUnavailable`, `N8nMainUnavailable` и `N8nWebhookUnavailable` перешли в `firing`; Telegram доставил три красных сообщения. После возврата реплики все Pod стали Ready, список активных алертов опустел и пришли три зелёных сообщения. Production не останавливался. Node-exporter показывает 20 009 996 288 доступных байт на корневом ext4-диске VM кластера, доля свободного места — 61,4%; правило `NodeDiskNearlyFull` установлено, но заполнение диска для проверки не создавалось.

Дашборд дополнен p95 времени webhook-исполнений и долей неуспешных задач очереди за час. После одного нового тестового webhook-запроса счётчик duration вырос с 12 до 13, Prometheus вернул p95 9,75 с из-за грубых границ histogram buckets; формула доли ошибок вернула 0. Алерт `PostgresDatabaseGrowing` срабатывает при росте текущего размера базы более чем на 25 МиБ относительно минимума за час в течение 5 минут; запрос к обеим базам вернул реальные ряды, но порог искусственно не достигался.

На единственном доступном ПК включён пользовательский `do14-backup.timer` (ежедневно в 03:00). Первый запуск `do14-backup.service` создал production-копию `~/.local/share/do14-backups/production/20260925T151506Z`; `sha256sum -c` подтвердил дамп, ключ и Helm values. Каталог имеет права `0700`. Еженедельный `do14-backup-verify.timer` назначен на воскресенье 04:00; ручной запуск его сервиса восстановил этот дамп в одноразовый PostgreSQL 17.6 без опубликованных портов и нашёл 142 таблицы и 2 credentials. Проверка не расшифровывает credentials ключом n8n; это отдельно подтверждено прежним восстановлением приложения. Оба таймера имеют `Persistent=true`, но при `Linger=no` работают во время пользовательской сессии и догоняют пропущенный запуск после входа. Ежедневные копии остаются на одном ПК и не зашифрованы отдельно от его учётной записи.

Копия `20260925T154851Z` вручную зашифрована GPG AES-256 в `DO14-backups/production-20260925T154851Z.tar.gpg` на USB-носителе. Исходные файлы до экспорта прошли `sha256sum -c`. Проверка USB-архива потребовала парольную фразу, показала четыре ожидаемых файла и распаковала их во временный каталог `0700`; там все три контрольные суммы совпали. Открытые временные файлы затем удалены, архив синхронизирован с накопителем. Парольную фразу нужно хранить отдельно от ПК и флешки: без неё архив не восстановить. Снимок USB пока не обновляется автоматически.

Предыдущие временные namespaces `do14-restore-test` и `do14-restore-workflow` удалены после проверки; восстановление из сохранённых локальных копий остаётся возможным. `do14-restore-credential` пока оставлен для просмотра результата. USB содержит отдельный проверенный зашифрованный снимок, но полное восстановление приложения именно из этого архива после потери ПК не репетировалось.

## Оставшиеся опыты

- Несовпадающий ключ main/worker: зафиксировать конкретный симптом на workflow с сохранёнными credentials, не публикуя значения ключей.
- Настроить отдельную политику повторов, если требуется гарантированное завершение задания после принудительной потери worker.
- Остановка Redis: зафиксировать деградацию main, webhook и worker.
- Полная репетиция восстановления из USB-архива после удаления локального стенда и регулярное обновление USB-снимка.

Эти пункты намеренно не названы пройденными: результат должен быть получен экспериментально.
