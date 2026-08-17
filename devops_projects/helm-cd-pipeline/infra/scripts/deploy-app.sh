#!/bin/bash
# deploy-app.sh — разворачивание приложения в локальном кластере k3s.
#
# Вызывается автоматически из Vagrantfile (trigger after :up у последней ноды),
# но идемпотентен и рассчитан на то, что его будут гонять руками сколько угодно:
#   bash infra/scripts/deploy-app.sh
#
# Работает с хоста через kubeconfig, а не по SSH на мастер. Причина: synced_folder
# у провайдера libvirt — это rsync-копия, а не монтирование, и чарт из репозитория
# появился бы внутри машины только после vagrant rsync. С хоста этой проблемы нет.
#
# Про паузы между стадиями. kubectl apply возвращает управление сразу — объект
# лишь записан в etcd, контроллеры ещё не отработали. Поэтому между стадиями
# стоит и `kubectl wait` по конкретному условию, и короткий sleep сверху.

set -euo pipefail

MASTER_IP="192.168.60.10"
NAMESPACE="staging"
RELEASE="myapp"

# Пути считаем от каталога скрипта, чтобы вызов работал из любого cwd.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_DIR="$(dirname "$INFRA_DIR")"
CHART_DIR="${PROJECT_DIR}/helm/myapp"

# Kubeconfig именно этого кластера. Указываем явно и всегда: в ~/.kube/config
# лежит совсем другой кластер, и без этого команды молча уйдут не туда.
export KUBECONFIG="${HELM_CD_KUBECONFIG:-$HOME/.kube/helm-cd-config}"

# Учётные данные и ключи лежат ВНЕ репозитория. Шаблон файла и команды
# генерации ключей — в infra/secrets.env.example.
SECRETS_DIR="${HELM_CD_SECRETS_DIR:-$HOME/.helm-cd}"

# Пауза между стадиями: ждём, пока контроллеры разберут только что поданное.
PAUSE="${HELM_CD_STAGE_PAUSE:-5}"

echo "============================================"
echo "  Разворачивание приложения"
echo "  кластер  = ${MASTER_IP} (${KUBECONFIG})"
echo "  release  = ${RELEASE} в неймспейсе ${NAMESPACE}"
echo "  чарт     = ${CHART_DIR}"
echo "============================================"

stage() {
    echo ""
    echo "[$1] $2"
}

die() { echo "ОШИБКА: $*" >&2; exit 1; }

[ -d "$CHART_DIR" ]   || die "не найден чарт ${CHART_DIR}"
[ -f "$KUBECONFIG" ]  || die "не найден kubeconfig ${KUBECONFIG}"
command -v kubectl >/dev/null || die "на хосте нет kubectl"
command -v helm    >/dev/null || die "на хосте нет helm"

for f in secrets.env private_key.txt public_key.txt; do
    [ -f "${SECRETS_DIR}/${f}" ] || die "нет файла ${SECRETS_DIR}/${f}.
Учётные данные хранятся вне репозитория. Скопируйте infra/secrets.env.example
в ${SECRETS_DIR}/secrets.env, задайте пароли и сгенерируйте пару ключей
командами из шапки того же файла."
done

# shellcheck disable=SC1090,SC1091
set -a; source "${SECRETS_DIR}/secrets.env"; set +a

# --------------------------------------------------------------------------
stage 1/6 "Ждём, пока обе ноды станут Ready"
until [ "$(kubectl get nodes --no-headers 2>/dev/null | grep -c ' Ready ')" -ge 2 ]; do
    echo "  -> нод Ready пока меньше двух, ждём..."
    sleep 3
done
kubectl wait --for=condition=Ready node --all --timeout=300s
kubectl get nodes
sleep "$PAUSE"

# --------------------------------------------------------------------------
stage 2/6 "Проверяем инструменты"
echo "  -> kubectl: $(kubectl version --client -o json 2>/dev/null | python3 -c 'import sys,json;print(json.load(sys.stdin)["clientVersion"]["gitVersion"])' 2>/dev/null || echo ok)"
echo "  -> helm:    $(helm version --short)"
sleep "$PAUSE"

# --------------------------------------------------------------------------
stage 3/6 "ingress-nginx"
# В k3s-master.sh стоит --disable=traefik, штатного ingress-контроллера нет.
# Он нужен тестам: коллекция ходит на один хост, а сервиса за ним два
# (session-service и gateway-service), развести их можно только по путям.
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.10.1/deploy/static/provider/cloud/deploy.yaml

# Сначала дожидаемся появления самого пода. Без этого цикла kubectl wait,
# запущенный сразу после apply, падает с "no matching resources found":
# Deployment уже создан, а пода под него ещё нет, и ждать wait нечего.
echo "  -> ждём появления пода контроллера"
until [ "$(kubectl get pods -n ingress-nginx \
           -l app.kubernetes.io/component=controller \
           --no-headers 2>/dev/null | wc -l)" -ge 1 ]; do
    sleep 3
done
kubectl wait --namespace ingress-nginx --for=condition=ready pod \
    --selector=app.kubernetes.io/component=controller --timeout=300s
echo "  -> контроллер Ready"
# Отдельная пауза, длиннее обычной: под уже Ready, но admission webhook
# принимает соединения на пару секунд позже, и без этой задержки следующая
# стадия падает на объекте Ingress с "failed calling webhook".
# В конвейере вебхук просто выключается — там проверять Ingress нечем и незачем,
# здесь он остаётся включённым, как и был бы в настоящем кластере.
echo "  -> ждём admission webhook (15 c)"
sleep 15

# --------------------------------------------------------------------------
stage 4/6 "helm upgrade --install ${RELEASE}"
# Секрет создаёт сам чарт. Значения приходят снаружи: пароли из secrets.env,
# ключи — файлами через --set-file. Ни то, ни другое в репозитории не лежит.
#
# Если какое-то значение забыто, установка падает сразу и с внятным текстом,
# а не через несколько минут девятью подами в CrashLoopBackOff.
helm upgrade --install "${RELEASE}" "${CHART_DIR}" \
    --namespace "${NAMESPACE}" --create-namespace \
    -f "${CHART_DIR}/values-local.yaml" \
    --set-string secret.data.POSTGRES_USER="${POSTGRES_USER}" \
    --set-string secret.data.POSTGRES_PASSWORD="${POSTGRES_PASSWORD}" \
    --set-string secret.data.RABBIT_MQ_USER="${RABBIT_MQ_USER}" \
    --set-string secret.data.RABBIT_MQ_PASSWORD="${RABBIT_MQ_PASSWORD}" \
    --set-file secret.data.PRIVATE_KEY="${SECRETS_DIR}/private_key.txt" \
    --set-file secret.data.PUBLIC_KEY="${SECRETS_DIR}/public_key.txt" \
    --wait --timeout 15m
helm list -n "${NAMESPACE}"

# --------------------------------------------------------------------------
stage 5/6 "Сводка по старту сервисов"
# У всех подов есть startupProbe и readinessProbe, поэтому helm --wait теперь
# возвращается только когда приложение действительно готово принимать запросы.
# Прежде этой гарантии не было: под считался Running за 20-35 секунд до того,
# как Spring Boot заканчивал старт, и разрыв закрывался ожиданием вслепую.
#
# checksvc.sh остался, но роль у него другая: он не подменяет пробы, а просто
# показывает, за сколько поднялся каждый сервис. На код возврата не влияет.
bash "${SCRIPT_DIR}/checksvc.sh" "${NAMESPACE}" || true

# --------------------------------------------------------------------------
stage 6/6 "Итоговое состояние"
echo '--- Ноды ---';    kubectl get nodes
echo '';  echo '--- Поды ---';    kubectl get pods -n "${NAMESPACE}" -o wide
echo '';  echo '--- Сервисы ---'; kubectl get svc -n "${NAMESPACE}"
echo '';  echo '--- Ingress ---'; kubectl get ingress -n "${NAMESPACE}"
echo '';  echo '--- Потребление ---'
kubectl top nodes 2>/dev/null || echo '  (metrics-server ещё собирает данные)'
kubectl top pods -n "${NAMESPACE}" 2>/dev/null || true

echo ""
echo "============================================"
echo "  Готово."
echo "  Функциональные тесты с хоста:"
echo "    kubectl -n ingress-nginx port-forward svc/ingress-nginx-controller 8080:80 &"
echo "    newman run ${PROJECT_DIR}/tests/application_tests.postman_collection.json \\"
echo "      -e ${PROJECT_DIR}/tests/application_tests.postman_environment.json"
echo "============================================"
