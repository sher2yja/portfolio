# Отдельная VM для GitHub Actions

`runner/Vagrantfile` создаёт Ubuntu VM с 2 vCPU и 2 ГБ RAM без общей папки с хостом. Runner зарегистрирован в `sher2yja/portfolio` под именем `do14-runner` и label `do14-deploy`. Он не получает Docker socket, SSH-ключ хоста или административный kubeconfig. MTU 1400 нужен для TLS к службе GitHub Actions через текущую libvirt-сеть.

`configure-access.sh` создаёт роли только в `do14-helm` и `do14-production`, сервисный токен в первом namespace и kubeconfig внутри runner-VM. В этих namespace Helm может читать и изменять Secrets, включая учётные данные n8n; это остаётся риском при компрометации runner. В `kube-system` и на уровне кластера права отсутствуют. После смены IP app VM выполните `bash runner/configure-access.sh` повторно.

Workflow лежит в корне репозитория портфолио: `../../../.github/workflows/do14-n8n.yml`. Пуш в `main` с изменением проекта запускает build → test → staging. Production запускается только через `workflow_dispatch` с выбором `production`. Он развёрнут в `do14-production` с отдельными секретами и PVC; дамп, ключ и Helm values восстановлены в `do14-production-restore`.

Кластер скачал `ghcr.io/sher2yja/do14-n8n` без pull-secret при первом успешном staging-деплое; отдельное изменение видимости Packages не потребовалось. Если пакет станет приватным, настройте постоянный read-only pull-secret: `GITHUB_TOKEN` в job временный. Docker Hub используется только для базового образа n8n, собственный образ публикуется в GHCR.

Self-hosted runner в публичном репозитории остаётся рискованным даже в отдельной VM: чужой код при ошибочной конфигурации workflow может получить доступ к данным этих двух namespace. Не добавляйте `pull_request`/`pull_request_target` jobs на label `do14-deploy` и не расширяйте права сервисного аккаунта. При окончании работы выключите VM командой `cd runner && vagrant halt`; автоматический деплой после этого, конечно, остановится.
