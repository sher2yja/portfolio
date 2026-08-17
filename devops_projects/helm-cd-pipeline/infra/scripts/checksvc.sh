#!/bin/bash
# checksvc.sh — показывает, что Spring Boot в подах закончил старт.
#
# Скрипт считает в логах строку "Started ...Application in": по одной на сервис.
# Раньше он подменял собой отсутствующие пробы — "1/1 Running" наступало на
# 20-35 секунд раньше, чем приложение начинало отвечать, и разрыв закрывался
# ожиданием вслепую. Теперь у подов есть startupProbe и readinessProbe,
# готовность гарантирует сам Kubernetes, а этот скрипт остался как быстрый
# способ увидеть картину по всем семи сервисам одной командой.
#
# Запускается с хоста, его вызывает deploy-app.sh:
#   bash infra/scripts/checksvc.sh [namespace]

set -uo pipefail

NAMESPACE="${1:-staging}"
# Тот же kubeconfig, что и у deploy-app.sh: в ~/.kube/config лежит другой
# кластер, поэтому путь задаём явно, а не полагаемся на текущий контекст.
export KUBECONFIG="${KUBECONFIG:-$HOME/.kube/helm-cd-config}"

# database и rabbitmq сюда не входят: это не Spring Boot, такой строки
# в их логах нет вообще.
SERVICES="session-svc hotel-svc booking-svc payment-svc loyalty-svc report-svc gateway-svc"

echo "  сервис        стартов  статус"
fail=0
for d in $SERVICES; do
    # --tail=400 с запасом на строки Hibernate и конфигурации перед стартом,
    # чтобы не промахнуться мимо "Started ..." при большом логе.
    n=$(kubectl logs "deploy/$d" -n "$NAMESPACE" --tail=400 2>/dev/null \
        | grep -c "Started .*Application in")
    if [ "$n" -ge 1 ]; then
        printf "  %-13s %-8s ok\n" "$d" "$n"
    else
        printf "  %-13s %-8s ЕЩЁ НЕ СТАРТОВАЛ\n" "$d" "$n"
        fail=1
    fi
done

if [ "$fail" -ne 0 ]; then
    echo "  -> не все сервисы отметились в логах; смотри kubectl logs -n $NAMESPACE"
    exit 1
fi
echo "  -> все 7 сервисов стартовали"
