#!/bin/bash
# checksvc.sh — проверяет, что Spring Boot приложения в подах реально стартовали.
# У Deployment'ов нет readiness-проб, поэтому "1/1 Running" не значит "готово":
# Spring Boot стартует ещё 15-35 секунд после того, как контейнер уже Running.
# Выводит по одной строке на сервис: имя + сколько раз в последних 400 строках
# логов встретилась "Started ...Application in" (ожидается 1 у каждого).

set -euo pipefail

# Если KUBECONFIG не выставлен в этой сессии терминала — берём стандартный
# путь проекта, а не дефолтный ~/.kube/config (тот указывает на другой кластер).
export KUBECONFIG="${KUBECONFIG:-$HOME/.kube/do12-config}"
NAMESPACE="basic-kuber"

# database и rabbitmq сюда не входят — это не Spring Boot, у них нет такой
# строки в логах вообще.
for d in session-svc hotel-svc gateway-svc booking-svc loyalty-svc payment-svc report-svc; do
  printf "%-12s " "$d"
  # --tail=400: с запасом на строки конфигурации/Hibernate перед стартом,
  # чтобы не промахнуться мимо "Started ..." при большом логе.
  kubectl logs "deploy/$d" -n "$NAMESPACE" --tail=400 | grep -c "Started .*Application in"
done
