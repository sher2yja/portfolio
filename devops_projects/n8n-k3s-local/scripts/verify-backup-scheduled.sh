#!/usr/bin/env bash
set -euo pipefail

backup_root="${XDG_DATA_HOME:-$HOME/.local/share}/do14-backups/production"
latest="$(find "$backup_root" -mindepth 1 -maxdepth 1 -type d -name '20??????T??????Z' -printf '%f\n' | sort | tail -n 1)"
[[ -n "$latest" ]] || { echo "Production-копия не найдена" >&2; exit 1; }
backup_dir="$backup_root/$latest"
(cd "$backup_dir" && sha256sum -c SHA256SUMS)
grep -q '^N8N_ENCRYPTION_KEY=.' "$backup_dir/n8n.env"

container_id="$(docker run --rm -d --network none --memory 512m --cpus 1 --tmpfs /var/lib/postgresql/data:rw,size=256m -e POSTGRES_HOST_AUTH_METHOD=trust postgres:17.6-alpine)"
trap 'docker rm -f "$container_id" >/dev/null 2>&1 || true' EXIT

for attempt in {1..30}; do
  if docker exec "$container_id" pg_isready -U postgres -d postgres >/dev/null 2>&1; then
    break
  fi
  sleep 1
done
docker exec "$container_id" pg_isready -U postgres -d postgres >/dev/null
docker exec -i "$container_id" pg_restore -U postgres -d postgres --exit-on-error --no-owner --no-privileges < "$backup_dir/n8n.dump"
tables="$(docker exec "$container_id" psql -U postgres -d postgres -tAc "SELECT count(*) FROM information_schema.tables WHERE table_schema='public'")"
credentials="$(docker exec "$container_id" psql -U postgres -d postgres -tAc 'SELECT count(*) FROM credentials_entity')"
[[ "$tables" -ge 100 && "$credentials" -ge 1 ]] || {
  echo "Контрольные запросы не пройдены: таблиц=$tables, credentials=$credentials" >&2
  exit 1
}
echo "Проверка копии $latest: восстановление успешно, таблиц=$tables, credentials=$credentials"
