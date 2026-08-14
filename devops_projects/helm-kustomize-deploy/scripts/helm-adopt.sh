#!/bin/bash
# helm-adopt.sh — "усыновляет" существующие Deployment/Service под Helm-релиз
# do12, не удаляя и не пересоздавая объекты.
#
# Helm 3 считает объект своим, если на нём стоят:
#   - label      app.kubernetes.io/managed-by=Helm
#   - аннотации  meta.helm.sh/release-name=<RELEASE_NAME>
#                meta.helm.sh/release-namespace=<NAMESPACE>
# Без них `helm install` в занятый namespace откажет с
# "invalid ownership metadata". После этого скрипта можно ставить релиз:
#   helm install do12 helm/myapp --namespace basic-kuber
# либо из архива, собранного заранее:
#   helm package helm/myapp -d helm/
#   helm install do12 helm/myapp-0.1.0.tgz --namespace basic-kuber

set -euo pipefail

# Если KUBECONFIG не выставлен в этой сессии терминала — берём стандартный
# путь проекта, а не дефолтный ~/.kube/config (тот указывает на другой кластер).
export KUBECONFIG="${KUBECONFIG:-$HOME/.kube/do12-config}"
NAMESPACE="basic-kuber"
RELEASE_NAME="do12"

# Имена Deployment и Service у одного и того же сервиса разные
# поэтому два списка и два отдельных цикла ниже, а не один общий.
DEPLOYMENTS=(database rabbitmq session-svc hotel-svc payment-svc report-svc loyalty-svc booking-svc gateway-svc)
SERVICES=(db rabbitmq session-service hotel-service payment-service report-service loyalty-service booking-service gateway-service)

# Проставляем label+аннотации на все 9 Deployment.
# --overwrite — чтобы скрипт можно было безопасно перезапускать повторно.
for d in "${DEPLOYMENTS[@]}"; do
  kubectl label deployment "$d" -n "$NAMESPACE" app.kubernetes.io/managed-by=Helm --overwrite
  kubectl annotate deployment "$d" -n "$NAMESPACE" \
    meta.helm.sh/release-name="$RELEASE_NAME" meta.helm.sh/release-namespace="$NAMESPACE" --overwrite
done

# То же самое для всех 9 Service.
for s in "${SERVICES[@]}"; do
  kubectl label service "$s" -n "$NAMESPACE" app.kubernetes.io/managed-by=Helm --overwrite
  kubectl annotate service "$s" -n "$NAMESPACE" \
    meta.helm.sh/release-name="$RELEASE_NAME" meta.helm.sh/release-namespace="$NAMESPACE" --overwrite
done
