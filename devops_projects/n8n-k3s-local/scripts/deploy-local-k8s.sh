#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
if [[ ! -f .env ]] || grep -q CHANGE_ME .env; then
  echo 'Сначала создайте рабочий .env: bash scripts/init-local-env.sh' >&2
  exit 1
fi

bash scripts/vm-kubectl.sh apply -f k8s/base/00-namespace.yaml
kubectl -n do14 create secret generic n8n-secrets \
  --from-env-file=.env --dry-run=client -o yaml | bash scripts/vm-kubectl.sh apply -f -
bash scripts/vm-kubectl.sh apply -f k8s/base/01-config.yaml
bash scripts/vm-kubectl.sh apply -f k8s/base/02-postgres.yaml
bash scripts/vm-kubectl.sh apply -f k8s/base/03-redis.yaml
bash scripts/vm-kubectl.sh -n do14 rollout status statefulset/postgres --timeout=5m
bash scripts/vm-kubectl.sh -n do14 rollout status statefulset/redis --timeout=5m
bash scripts/vm-kubectl.sh apply -f k8s/base/04-main.yaml
bash scripts/vm-kubectl.sh apply -f k8s/base/05-worker.yaml
bash scripts/vm-kubectl.sh apply -f k8s/base/06-webhook.yaml
bash scripts/vm-kubectl.sh -n do14 rollout status deployment/n8n-main --timeout=8m
bash scripts/vm-kubectl.sh -n do14 rollout status deployment/n8n-worker --timeout=8m
bash scripts/vm-kubectl.sh -n do14 rollout status deployment/n8n-webhook --timeout=8m
