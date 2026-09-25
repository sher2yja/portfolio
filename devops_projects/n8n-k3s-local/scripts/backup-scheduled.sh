#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
umask 077
backup_root="${XDG_DATA_HOME:-$HOME/.local/share}/do14-backups/production"
mkdir -p -m 700 "$backup_root"
chmod 700 "$backup_root"

exec 9>"$backup_root/.lock"
flock -n 9 || { echo "Копирование уже запущено" >&2; exit 1; }

backup_dir="$backup_root/$(date -u +%Y%m%dT%H%M%SZ)"
bash scripts/backup-local.sh "$backup_dir" do14-production .env.production
(cd "$backup_dir" && sha256sum -c SHA256SUMS)

# Keep the newest 14 verified backups. Leave unverified directories for inspection.
verified=0
while IFS= read -r candidate; do
  [[ -d "$candidate" && ! -L "$candidate" ]] || continue
  [[ -f "$candidate/n8n.dump" && -f "$candidate/n8n.env" && -f "$candidate/values.yaml" && -f "$candidate/SHA256SUMS" ]] || continue
  if (cd "$candidate" && sha256sum n8n.dump n8n.env values.yaml | cmp -s - SHA256SUMS); then
    ((verified += 1))
    if ((verified > 14)); then
      rm -rf -- "$candidate"
    fi
  fi
done < <(find "$backup_root" -mindepth 1 -maxdepth 1 -type d -regextype posix-extended -regex '.*/[0-9]{8}T[0-9]{6}Z' | sort -r)
