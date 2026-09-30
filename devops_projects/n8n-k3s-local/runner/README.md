# Отдельная VM для GitHub Actions

## Текущая WSL-среда, 30.09.2026

Дополнительно подготовлен `do14-runner-wsl` в `/home/devops1/work/n8n-github-runner`, VM `n8n-github-runner_default`, адрес `192.168.121.186`. GitHub API подтвердил online. Прежний `do14-runner` сохранён и остаётся offline. Новый runner обслуживает локальный кластер портфолио `192.168.121.254`; школьный GitLab использует другой кластер.

VM создана из этого Vagrantfile: Ubuntu 24.04, KVM, 2 CPU; первоначально 2 GiB, теперь 1 GiB RAM. Actions Runner 2.337.0 проверен по SHA-256 из release API GitHub. Установлены Node 22.23.3, Helm 3.21.3, kubectl 1.35.8, Newman 6.2.1. Kubeconfig в `/home/vagrant/.kube/config`, права 0600; ServiceAccount do14-deployer имеет права только в namespace приложения. Проверены exec, port-forward и отказ чтения Secrets kube-system. Docker daemon в runner VM не установлен: сборка выполняется на GitHub-hosted ubuntu-latest.

Runner запущен systemd-службой `actions.runner.sher2yja-portfolio.do14-runner-wsl.service` от vagrant. Label `do14-deploy`. Временный registration token после настройки удалён с хоста и из VM. Постоянные credentials Runner остаются внутри VM.

```bash
cd /home/devops1/work/n8n-github-runner
export VAGRANT_DEFAULT_PROVIDER=libvirt
vagrant up
vagrant ssh -c 'sudo systemctl status actions.runner.sher2yja-portfolio.do14-runner-wsl.service --no-pager'
# По завершении работы:
vagrant halt
```

Держите сеанс WSL открытым во время работы VM. Эти команды относятся к подготовленной копии вне OneDrive. GitHub environments do14-staging/do14-production получили существующие значения приложения, PULL_USER и проверенный classic PAT read:packages в PULL_TOKEN. Новый удалённый workflow прошёл build, четыре validate и test. Память 1 GiB для runner и 4 GiB для приложения применена к существующим VM и проверена этим прогоном. Полный автоматический цикл со staging подтверждён прогоном [36740012926](https://github.com/sher2yja/portfolio/actions/runs/36740012926), отдельный ручной production — [36741456740](https://github.com/sher2yja/portfolio/actions/runs/36741456740). Оба используют проверенный тег `2e31d6f8356591c1bbc50e0cd25c309998b28516`.

На хосте с 16 ГБ RAM одновременно включённые app VM (6 GiB) и runner VM (2 GiB) оставили Windows около 1,9 ГБ свободной памяти. После проверок обе VM штатно остановлены и выполнен `wsl --shutdown`; свободная память выросла до 7,9 ГБ. Запускайте стенд только на время интеграционной проверки/CI. Пока runner VM остановлена, GitHub показывает runner offline; это ожидаемо.

Повторный GitHub-прогон [36731183090](https://github.com/sher2yja/portfolio/actions/runs/36731183090) прошёл build/validate/test при памяти приложения 4 GiB и нового runner 1 GiB. Newman выполнил 10 assertions без ошибок, оба шага очистки успешны. Во время работы свободная RAM Windows падала до 0,6 GiB; после остановки обеих VM и WSL выросла до 8,28 GiB. После последующего успешного полного staging и отдельного ручного production обе VM и WSL выключены; свободная RAM Windows составила 6,69 GiB. Runner offline до следующего запуска VM.

## Историческая runner-VM

Ранняя версия `runner/Vagrantfile` создавала Ubuntu VM с 2 vCPU и 2 ГБ RAM без общей папки с хостом; текущая задаёт 1 GiB. Исторический runner зарегистрирован в `sher2yja/portfolio` под именем `do14-runner` и label `do14-deploy`. Он не получает Docker socket, SSH-ключ хоста или административный kubeconfig. MTU 1400 нужен для TLS к службе GitHub Actions через текущую libvirt-сеть.

`configure-access.sh` создаёт роли только в `do14-helm` и `do14-production`, сервисный токен в первом namespace и kubeconfig внутри runner-VM. В этих namespace Helm может читать и изменять Secrets, включая учётные данные n8n; это остаётся риском при компрометации runner. В `kube-system` и на уровне кластера права отсутствуют. После смены IP app VM выполните `bash runner/configure-access.sh` повторно.

Workflow лежит в корне репозитория портфолио: `../../../.github/workflows/do14-n8n.yml`. Пуш в `main` с изменением проекта запускает build → test → staging. Production запускается только через `workflow_dispatch` с выбором `production`. Он развёрнут в `do14-production` с отдельными секретами и PVC; дамп, ключ и Helm values восстановлены в `do14-production-restore`.

Кластер скачал `ghcr.io/sher2yja/do14-n8n` без pull-secret при первом успешном staging-деплое; отдельное изменение видимости Packages не потребовалось. Если пакет станет приватным, настройте постоянный read-only pull-secret: `GITHUB_TOKEN` в job временный. Docker Hub используется только для базового образа n8n, собственный образ публикуется в GHCR.

Self-hosted runner в публичном репозитории остаётся рискованным даже в отдельной VM: чужой код при ошибочной конфигурации workflow может получить доступ к данным этих двух namespace. Не добавляйте `pull_request`/`pull_request_target` jobs на label `do14-deploy` и не расширяйте права сервисного аккаунта. При окончании работы выключите VM командой `cd runner && vagrant halt`; автоматический деплой после этого, конечно, остановится.
