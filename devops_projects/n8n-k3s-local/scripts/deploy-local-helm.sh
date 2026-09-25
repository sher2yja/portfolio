#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
namespace="${1:-do14-helm}"
values_file="${2:-chart/values-staging.yaml}"
if [[ ! -f .env ]] || grep -q CHANGE_ME .env; then
  echo 'Сначала создайте рабочий .env: bash scripts/init-local-env.sh' >&2
  exit 1
fi
if [[ ! -f "$values_file" ]]; then
  echo "Файл значений не найден: $values_file" >&2
  exit 1
fi

kubectl create namespace "$namespace" --dry-run=client -o yaml |
  bash scripts/vm-kubectl.sh apply -f -
kubectl -n "$namespace" create secret generic n8n-secrets \
  --from-env-file=.env --dry-run=client -o yaml |
  bash scripts/vm-kubectl.sh apply -f -
bash scripts/vm-kubectl.sh -- helm upgrade --install do14 chart \
  --namespace "$namespace" -f "$values_file" \
  --set existingSecret=n8n-secrets --wait --timeout 10m
