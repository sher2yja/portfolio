# n8n: передаваемая часть Сани

Рабочие файлы находятся в этом каталоге. `main`, `webhook`, `worker` — роли n8n в queue mode; `runner` — внешний n8n task-runner в Pod worker. GitLab Runner устанавливается отдельно. Принятие трёх ролей как трёх микросервисов подтверждает проверяющий.

## 1. Чистый хост Ubuntu 22.04

Команды выполняются в Linux. В WSL используйте Ubuntu 24.04 с systemd; рабочий каталог, секреты, kubeconfig и диски VM храните в Linux filesystem, вне OneDrive. Для виртуальной машины нужны аппаратная виртуализация, `/dev/kvm` и свободная память для гостя с 4 CPU / 4 GiB. GitHub runner VM получает 1 GiB. Первые интеграционные проверки выполнены при 6 + 2 GiB; Полный GitHub цикл с автоматическим staging и отдельным ручным production успешно выполнен при 4 + 1 GiB, см. [отчёт](report.md). На Windows с 16 GiB RAM свободная память во время прогона падала до 0,6 GiB; запускайте обе VM только на время проверки. Воспроизведение на чистой Ubuntu 22.04 остаётся открытым.

```bash
sudo apt-get update
sudo apt-get install -y git openssh-client docker.io qemu-kvm libvirt-daemon-system libvirt-clients \
  ansible curl ca-certificates xz-utils unzip ruby-dev libvirt-dev build-essential rsync
sudo systemctl enable --now docker libvirtd
sudo usermod -aG docker,kvm,libvirt "$USER"
# Выйти из сеанса и войти снова, чтобы применились группы.
```

Установите Vagrant 2.4.9 из официального Debian-пакета HashiCorp:

```bash
task_install_dir=$(mktemp -d)
cd "$task_install_dir"
curl -fsSLO https://releases.hashicorp.com/vagrant/2.4.9/vagrant_2.4.9-1_amd64.deb
curl -fsSLO https://releases.hashicorp.com/vagrant/2.4.9/vagrant_2.4.9_SHA256SUMS
grep '  vagrant_2.4.9-1_amd64.deb$' vagrant_2.4.9_SHA256SUMS | sha256sum -c -
sudo apt-get install -y ./vagrant_2.4.9-1_amd64.deb
cd -
rm -rf -- "$task_install_dir"
```

Из каталога `src/`:

```bash
vagrant plugin install vagrant-libvirt --plugin-version 0.12.2
export VAGRANT_DEFAULT_PROVIDER=libvirt
sudo bash tools/install-cli.sh
docker version
test -r /dev/kvm && test -w /dev/kvm
virsh -c qemu:///system list --all
sudo virsh net-autostart default
sudo virsh net-start default # если сеть ещё не запущена
vagrant up --provider=libvirt
vagrant provision          # второй прогон: ожидается changed=0
```

Vagrantfile закрепляет Ubuntu 24.04 (`bento/ubuntu-24.04`, `202508.03.0`), Ansible — k3s `v1.35.8+k3s1`. Инструменты CI: Bash, Docker CLI/daemon, Node 22, Newman 6.2.1, Helm 3.21.3, kubectl 1.35.8, curl, OpenSSL. Фактически выполненные проверки перечислены в [report.md](report.md); наличие команды в инструкции не означает успешный прогон.

## 2. Kubeconfig и namespace

### Подготовленная локальная WSL-среда

В этой проверке рабочая копия находится в `/home/devops1/work/n8n-src`, приватные kubeconfig — в `/home/devops1/work/n8n-verification`. Docker Engine работает внутри Ubuntu, Docker Desktop не требуется. Откройте терминал Ubuntu и оставляйте его открытым во время работы VM: завершение WSL останавливает гостя.

```bash
cd /home/devops1/work/n8n-src
export VAGRANT_DEFAULT_PROVIDER=libvirt
vagrant up --no-provision
export KUBECONFIG=/home/devops1/work/n8n-verification/operator.yaml
kubectl get pods -n do14-helm
```

На этом Windows-хосте для прямого доступа через VPN настроен `%USERPROFILE%\.wslconfig`:

```ini
[wsl2]
memory=6GB
networkingMode=mirrored
[experimental]
ignoredPorts=67
```

Исключение порта 67 позволяет DHCP libvirt работать при занятом порте Windows. После изменения настроек сначала выполните `vagrant halt`, затем `wsl --shutdown` из PowerShell. Настройка относится к этому WSL-хосту; на чистой Ubuntu она не нужна. См. [настройки WSL](https://learn.microsoft.com/en-us/windows/wsl/wsl-config).

Получите kubeconfig оператора из VM и замените loopback API на адрес VM:

```bash
umask 077
mkdir -p "$HOME/.kube"
vagrant ssh -c 'sudo cat /etc/rancher/k3s/k3s.yaml' | tr -d '\r' > "$HOME/.kube/do14.yaml"
vm_ip=$(vagrant ssh-config | awk '$1 == "HostName" {print $2; exit}')
sed -i "s/127.0.0.1/$vm_ip/" "$HOME/.kube/do14.yaml"
export KUBECONFIG="$HOME/.kube/do14.yaml"
kubectl get nodes
kubectl apply -f runner/rbac.yaml
```

RBAC создаёт оператор. CI job не создаёт namespace. Не переносите этот kubeconfig администратора в job: job использует ServiceAccount `do14-ci-job`.

## 3. Сборка, проверка кандидата, деплой

Создайте приватный файл вне checkout по образцу `.env.example`, права `0600`. Значения генерируйте один раз и храните отдельно для staging и production. `REGISTRY` — префикс repository, например `registry.school.example/group/project`; четыре образа получают суффиксы `/main`, `/webhook`, `/worker`, `/runner`. `IMAGE_TAG` — SHA проверяемого коммита. Push credentials нужны только сборке; `PULL_USER` / `PULL_TOKEN` — read-only deploy token для k3s.

```bash
set -a
source "$HOME/.config/do14/build.env"
set +a
bash ci/build.sh
bash ci/test-candidate.sh

# После успешного теста загрузить секреты выбранного окружения,
# сохраняя тот же REGISTRY и IMAGE_TAG.
set -a
source "$HOME/.config/do14/staging.env"
set +a
bash ci/deploy.sh staging
# Затем аналогично production.env:
bash ci/deploy.sh production
```

`Chart.yaml: appVersion` — единственный источник версии n8n и task-runner (2.40.7). Dockerfile задаёт команду роли. PostgreSQL и Redis используют штатные образы.

Здесь 2.40.7 означает release tag обоих официальных базовых образов. Внутренний npm-пакет `@n8n/task-runner` в официальном runners:2.40.7 имеет отдельную версию 2.40.3; она не переименовывается.

Постоянный release `do14`: staging namespace `do14-helm`, main/webhook NodePort **30678/30679**; production namespace `do14-production`, порты **31678/31679**. Открывайте `http://<VM-IP>:30678` с хоста. Пять Pod на релиз: main, webhook, worker с двумя контейнерами, PostgreSQL, Redis. HTTP без TLS предназначен для изолированного учебного стенда.

Повторный deploy отказывается заменять существующие ключ шифрования, пароль БД и runner auth token. При переносе действующего `do14` сначала сохраните его текущие значения; имена StatefulSet и PVC сохранены. Не удаляйте release и PVC для обновления.

`test-candidate.sh` создаёт уникальный `do14-test-*` внутри `do14-helm`, отдельные PVC и одноразовые секреты. Доступ идёт через localhost port-forward; owner создаётся на свежей БД, workflow импортируется и публикуется, процессы перезапускаются, Newman проверяет health/readiness и функциональный webhook с уникальным входом и Code-узлом. После успеха и ошибки сохраняются журналы в `artifacts/`, затем удаляются только собственные ресурсы кандидата. `test.sh <main_base_url>` используется этой обёрткой с `WEBHOOK_BASE_URL` и `HELM_RELEASE`.

Чтобы два постоянных окружения и кандидат помещались в VM на 4 GiB, n8n использует request 256 MiB; лимиты сохранены: staging/candidate 1 GiB, production 2 GiB. Чартовые проверки контролируют суммарные requests трёх релизов. Диски VM используют `cache=none`, чтобы уменьшить двойное кеширование в гостевой ОС и WSL.

CI задаёт уникальное `TEST_RELEASE=do14-test-<run-id>-<attempt>`. При принудительной отмене job runner может завершить процессы до окончания trap, поэтому GitHub дополнительно вызывает общий скрипт с `--cleanup-only` в шаге `always()`. Аналогичную очистку следует вызвать в GitLab `after_script`, сохраняя тот же TEST_RELEASE. Повторная очистка не требует Registry credentials; namespace фиксирован, имя do14 отклоняется:

```bash
TEST_RELEASE=do14-test-123-1 bash ci/test-candidate.sh --cleanup-only
```

## 4. CI и передача

GitHub Actions в корне portfolio собирает четыре образа в GHCR, выполняет проверки Helm/Kubernetes/Trivy, проверяет кандидата на существующем self-hosted runner, автоматически обновляет staging. Production запускается через workflow_dispatch после staging. В GitHub environments `do14-staging` и `do14-production` нужны три постоянных секрета приложения и `PULL_USER`, `PULL_TOKEN`; значения должны совпадать с существующим кластером.

Школьный GitLab использует **отдельный кластер Максима**. Регистрация, версии и проверка С1 описаны в [runner/NOTES.md](runner/NOTES.md). Каталог `../runner` относится к старому GitHub runner.

Для GHCR pull создайте GitHub PAT **classic** с единственным scope `read:packages` и ограниченным сроком действия. Это `PULL_TOKEN`; `PULL_USER` — login владельца доступа. Для push Actions использует автоматический `GITHUB_TOKEN` с `packages: write`. См. [официальную документацию GHCR](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry). Не используйте registration token Runner в качестве Registry token.

В GitHub Settings → Environments → каждое из `do14-staging` / `do14-production` добавьте Environment secrets: `N8N_ENCRYPTION_KEY`, `N8N_RUNNERS_AUTH_TOKEN`, `POSTGRES_PASSWORD`, `PULL_USER`, `PULL_TOKEN`. Три значения приложения берите из соответствующего действующего кластера. CLI позволяет загрузить значение из приватного файла без включения его в командную строку:

```bash
gh secret set PULL_TOKEN --repo sher2yja/portfolio --env do14-staging < "$HOME/.config/do14/ghcr-read-token.txt"
gh secret set PULL_TOKEN --repo sher2yja/portfolio --env do14-production < "$HOME/.config/do14/ghcr-read-token.txt"
```

Контракт финального `.gitlab-ci.yml` Максима: build/test автоматически для `feature_*`, staging вручную после test, production вручную после staging; в обоих деплоях один проверенный тег. Если постоянные секреты protected, деплой должен выполняться из защищённой ветки (например develop), куда перенесён проверенный SHA. Не делайте protected секреты доступными произвольным feature-веткам.

Мониторинг, backup/restore, Telegram и исторические отчёты сохранены вне `src/`. Передача закрывается только после реального С1 на школьном GitLab и воспроизведения Максимом на Ubuntu 22.04. Сейчас эти проверки открыты.

При обновлении прежнего do14 дополнительный cluster-summary удаляется из рабочего релиза. После обновления обоих окружений оператор восстанавливает его через `../ansible/host.yml`, который применяет отдельный чарт из `../monitoring/cluster-summary/`. Новый GitLab job не управляет этим дополнением.
