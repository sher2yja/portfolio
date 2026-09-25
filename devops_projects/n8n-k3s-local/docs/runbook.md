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
```

Если `ImagePullBackOff`, проверьте тег и права registry. Если main или worker не стартует, проверьте PostgreSQL, Redis, одинаковый `N8N_ENCRYPTION_KEY` и токен runner. Секреты в команды диагностики и отчёт не копируйте.

## Мониторинг и восстановление

После включения метрик main вернул `n8n_scaling_mode_queue_jobs_waiting 0` и `n8n_scaling_mode_queue_jobs_active 0`. Prometheus показал targets `n8n-main` и `n8n-webhook` в состоянии `up`, Grafana API нашёл дашборд `DO14 — n8n queue`. Четыре правила проверены `promtool check rules`. При масштабировании staging main до нуля `N8nMainUnavailable` перешёл в `pending`, затем `firing`; после восстановления main алерт исчез, а `/healthz` вновь ответил `{"status":"ok"}`. Production оставался работоспособен. Доставка уведомления и нагрузка проверены отдельными опытами ниже.

В production n8n работает `DO14 Telegram alerts`. Владелец задал chat ID и Telegram credential только в интерфейсе; токен и ID не находятся в JSON или Git. Для воспроизведения создайте отдельное состояние алертов и PostgreSQL credential, затем импортируйте `workflows/telegram-alerts.json` с подстановкой Telegram credential и chat ID внутри n8n:

```bash
bash scripts/vm-kubectl.sh -n do14-production exec -i do14-postgres-0 -- \
  psql -v ON_ERROR_STOP=1 -U n8n -d n8n < monitoring/alert-state.sql
bash scripts/import-local-postgres-credential.sh \
  do14-production .env.production DO14ProductionPgCredential 'DO14 production PostgreSQL'
```

Первый вариант workflow использовал static data. При одном `firing` два соседних запуска отправили два одинаковых сообщения; поэтому он заменён атомарным переходом состояния в PostgreSQL. SQL-транзакция с откатом дала одну строку для нового алерта, ноль для повтора и одну для снятия. В повторном опыте staging main был остановлен: Prometheus перешёл в `firing`, Telegram прислал одно красное сообщение; два последующих запуска Telegram-узел не вызывали. После восстановления main и `/healthz` пришло одно зелёное сообщение; в таблице `do14_ops.alert_state` состояние стало `firing=false`. Staging и production main вернулись к 1/1. Токен, временно использованный при этой проверке, нужно отозвать и заменить в Telegram credential, затем проверить отправку повторно.

Для опыта с очередью в staging импортирован и опубликован `workflows/queue-load.json`: каждый вызов webhook выполняет трёхсекундную задачу на worker. Один пробный запрос и затем 50 параллельных запросов вернули HTTP 200. Во время серии метрики main показали 15 ожидающих и 5 активных заданий, после серии — 0 и 0; счётчик завершённых заданий после рестарта main достиг 51, ошибок — 0. Это подтверждает рост и рассасывание очереди, но не проверяет автоматическое масштабирование.

`scripts/backup-local.sh` создал дамп, копию `.env` и values-файл, все с контрольными суммами. Первый `scripts/restore-local.sh` развернул их в новом `do14-restore-test` namespace: сначала приложение было масштабировано до нуля, после импорта дампа запущено; Helm завершился успешно. Исходная и восстановленная БД содержали по 142 публичные таблицы. Это был только тест механики.

После настройки владельца импортированы два workflow. `DO14 queue smoke` выполнился в основном namespace с ответом HTTP 200; worker зафиксировал execution 1. Копия с ним была восстановлена в `do14-restore-workflow`, где тот же webhook ответил HTTP 200, а worker завершил execution 2.

Для полного критерия `scripts/import-local-postgres-credential.sh` создал локальный PostgreSQL credential, не печатая пароль. Workflow `DO14 credential restore smoke` выполнил `SELECT 1 AS credential_ok` через этот credential и вернул `{"credential_ok":1}`. Бэкап `backups/20260925T112004Z` восстановлен в пустом `do14-restore-credential`; тот же webhook там снова вернул `{"credential_ok":1}`, а worker завершил execution 3. Это подтверждает совместное восстановление дампа и ключа шифрования, а не только наличие таблиц.

Предыдущие временные namespaces `do14-restore-test` и `do14-restore-workflow` удалены после проверки; восстановление из сохранённых локальных копий остаётся возможным. `do14-restore-credential` пока оставлен для просмотра результата. Все копии находятся на том же компьютере и не заменяют независимое внешнее хранилище.

## Оставшиеся опыты

- Несовпадающий ключ main/worker: зафиксировать конкретный симптом на workflow с сохранёнными credentials, не публикуя значения ключей.
- Убийство worker во время исполнения: измерить повторное выполнение и показать поведение очереди.
- Остановка Redis: зафиксировать деградацию main, webhook и worker.
- Проверка долгосрочного хранения: скопировать зашифрованную резервную копию на независимый носитель и повторить восстановление после удаления локального стенда.

Эти пункты намеренно не названы пройденными: результат должен быть получен экспериментально.
