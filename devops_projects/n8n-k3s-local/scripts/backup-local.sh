#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
umask 077
backup_dir="${1:-backups/$(date -u +%Y%m%dT%H%M%SZ)}"
namespace="${2:-do14-helm}"
env_file="${3:-.env}"
if [[ ! -f "$env_file" ]]; then
  echo "Файл окружения не найден: $env_file" >&2
  exit 1
fi
if [[ -e "$backup_dir" || -L "$backup_dir" ]]; then
  echo "Каталог уже существует: $backup_dir" >&2
  exit 1
fi
mkdir -p "$(dirname "$backup_dir")"
staging_dir="$(mktemp -d "$(dirname "$backup_dir")/.backup-incomplete.XXXXXXXX")"
trap 'rm -rf -- "$staging_dir"' EXIT

bash scripts/vm-kubectl.sh -n "$namespace" exec do14-postgres-0 -- \
  pg_dump -U n8n -d n8n -Fc > "$staging_dir/n8n.dump"
cp "$env_file" "$staging_dir/n8n.env"
bash scripts/vm-kubectl.sh -- helm get values do14 --namespace "$namespace" --all -o yaml > "$staging_dir/values.yaml"
(cd "$staging_dir" && sha256sum n8n.dump n8n.env values.yaml) > "$staging_dir/SHA256SUMS"
(cd "$staging_dir" && sha256sum -c --status SHA256SUMS)
mv -T -- "$staging_dir" "$backup_dir"
trap - EXIT
echo "Локальная копия создана: $backup_dir (содержит секреты, вне Git)"
