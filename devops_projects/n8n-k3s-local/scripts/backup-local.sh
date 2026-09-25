#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
if [[ ! -f .env ]]; then
  echo 'Файл .env не найден.' >&2
  exit 1
fi

umask 077
backup_dir="${1:-backups/$(date -u +%Y%m%dT%H%M%SZ)}"
if [[ -e "$backup_dir" ]]; then
  echo "Каталог уже существует: $backup_dir" >&2
  exit 1
fi
mkdir -p "$(dirname "$backup_dir")"
mkdir -m 700 "$backup_dir"

bash scripts/vm-kubectl.sh -n do14-helm exec do14-postgres-0 -- \
  pg_dump -U n8n -d n8n -Fc > "$backup_dir/n8n.dump"
cp .env "$backup_dir/n8n.env"
cp chart/values-staging.yaml "$backup_dir/values.yaml"
(cd "$backup_dir" && sha256sum n8n.dump n8n.env values.yaml) > "$backup_dir/SHA256SUMS"
echo "Локальная копия создана: $backup_dir (содержит секреты, вне Git)"
