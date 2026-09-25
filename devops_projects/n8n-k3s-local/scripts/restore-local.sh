#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
backup_dir="${1:?Укажите каталог резервной копии}"
namespace="${2:?Укажите новый namespace для восстановления}"
if [[ ! "$namespace" =~ ^[a-z][a-z0-9-]*$ ]] || [[ "$namespace" == do14-helm ]]; then
  echo 'Укажите новый namespace, отличный от do14-helm.' >&2
  exit 1
fi
for file in n8n.dump n8n.env values.yaml SHA256SUMS; do
  test -f "$backup_dir/$file"
done
(cd "$backup_dir" && sha256sum -c SHA256SUMS)
if bash scripts/vm-kubectl.sh get namespace "$namespace" >/dev/null 2>&1; then
  echo "Namespace уже существует, восстановление отменено: $namespace" >&2
  exit 1
fi

bash scripts/vm-kubectl.sh create namespace "$namespace"
kubectl -n "$namespace" create secret generic n8n-secrets \
  --from-env-file="$backup_dir/n8n.env" --dry-run=client -o yaml |
  bash scripts/vm-kubectl.sh apply -f -
bash scripts/vm-kubectl.sh -- helm install do14 chart -n "$namespace" \
  -f "$backup_dir/values.yaml" --set existingSecret=n8n-secrets \
  --set n8n.replicas=0 --wait --timeout 10m

bash scripts/vm-kubectl.sh -n "$namespace" wait --for=condition=Ready \
  pod/do14-postgres-0 --timeout=5m
bash scripts/vm-kubectl.sh -n "$namespace" exec -i do14-postgres-0 -- \
  pg_restore -U n8n -d n8n --no-owner --no-privileges < "$backup_dir/n8n.dump"
bash scripts/vm-kubectl.sh -- helm upgrade do14 chart -n "$namespace" \
  -f "$backup_dir/values.yaml" --set existingSecret=n8n-secrets \
  --wait --timeout 10m
echo "Дамп восстановлен в $namespace. Проверьте workflow с сохранённым credential."
