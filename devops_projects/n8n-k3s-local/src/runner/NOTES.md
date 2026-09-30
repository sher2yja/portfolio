# GitLab Runner и проверка С1

Используется официальный `gitlab/gitlab-runner`, Kubernetes executor, namespace `gitlab-runner`, тег `k8s`, concurrent=1. Менеджер и job имеют разные ServiceAccount. DinD с TLS требует privileged job; стенд предназначен для доверенного учебного проекта.

## Регистрация оператором

1. Узнать версию школьного GitLab и выбрать совместимую версию Runner. Выполнить `helm search repo gitlab/gitlab-runner --versions`, зафиксировать выбранную версию chart в передаваемой инструкции после С1. Пока версия сервера неизвестна, совместимость и chart version не подтверждены.
2. В GitLab создать project runner, тег `k8s`, отключить выполнение untagged jobs. Получить authentication token `glrt-*`. Токен не хранить в values или репозитории.
3. В приватный файл `runner-token` вне checkout записать токен без перевода строки; права `0600`.

```bash
kubectl apply -f runner/rbac.yaml
kubectl -n gitlab-runner create secret generic gitlab-runner-token \
  --from-file=runner-token="$HOME/.config/do14/runner-token" \
  --from-literal=runner-registration-token='' --dry-run=client -o yaml | kubectl apply -f -
helm repo add gitlab https://charts.gitlab.io
helm repo update
export RUNNER_CHART_VERSION='<выбранная совместимая версия>'
helm upgrade --install gitlab-runner gitlab/gitlab-runner \
  --version "$RUNNER_CHART_VERSION" -n gitlab-runner -f runner/values.yaml \
  --set-string gitlabUrl='https://<школьный-gitlab>/' --atomic --wait --timeout 10m
```

## С1: реальные проверки

`SMOKE.gitlab-ci.yml` — пример проверки С1, не финальный pipeline Максима. Образы Docker CLI и DinD согласованы на 24.0.5; DinD использует `/certs/client` и `DOCKER_TLS_CERTDIR=/certs`. Build job ставит Bash/curl, test job — Node 22, kubectl, Helm, Newman, curl/OpenSSL. Версию Docker необходимо подтвердить на выбранной версии Runner и сервере.

Проверить из VM и job DNS/TLS/HTTP до GitLab и Registry, регистрацию online, `docker info`, сборку четырёх образов, push, затем pull k3s через созданный deploy token. Для self-signed CA доверенный сертификат нужен отдельно VM, Runner, DinD и containerd k3s; не отключать TLS verification.

Проверить права операторским kubeconfig:

```bash
kubectl auth can-i create pods/exec -n do14-helm --as=system:serviceaccount:gitlab-runner:do14-ci-job
kubectl auth can-i create pods/portforward -n do14-production --as=system:serviceaccount:gitlab-runner:do14-ci-job
kubectl auth can-i get pods/log -n do14-helm --as=system:serviceaccount:gitlab-runner:do14-ci-job
kubectl auth can-i get secrets -n kube-system --as=system:serviceaccount:gitlab-runner:do14-ci-job # ожидается no
kubectl auth can-i create namespaces --as=system:serviceaccount:gitlab-runner:do14-ci-job # ожидается no
```

При появлении доступа к школьному GitLab С1 имеет первый приоритет. Сохранить job ID, версии, команды, реальные скриншоты online runner / push / Pod image pull. Пока эти доказательства отсутствуют, С1 открыта.
