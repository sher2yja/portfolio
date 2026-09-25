#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
namespace="${1:-do14-helm}"
env_file="${2:-.env}"
credential_id="${3:-DO14PgCredential}"
credential_name="${4:-DO14 local PostgreSQL}"
if [[ ! -f "$env_file" ]]; then
  echo "Сначала создайте $env_file." >&2
  exit 1
fi
password="$(awk -F= '$1 == "POSTGRES_PASSWORD" {print $2; exit}' "$env_file")"
if [[ -z "$password" ]] || [[ "$password" == *CHANGE_ME* ]]; then
  echo 'POSTGRES_PASSWORD не задан.' >&2
  exit 1
fi
user_id="$(bash scripts/vm-kubectl.sh -n "$namespace" exec do14-postgres-0 -- \
  psql -U n8n -d n8n -tAc 'select id from "user" limit 1')"
if [[ -z "$user_id" ]]; then
  echo 'В n8n ещё не создан владелец.' >&2
  exit 1
fi

# JSON идёт напрямую в CLI; пароль не попадает в аргументы процесса или Git.
POSTGRES_PASSWORD="$password" CREDENTIAL_ID="$credential_id" CREDENTIAL_NAME="$credential_name" node -e '
const data = [{
  id: process.env.CREDENTIAL_ID,
  name: process.env.CREDENTIAL_NAME,
  type: "postgres",
  data: {
    host: "do14-postgres",
    database: "n8n",
    user: "n8n",
    password: process.env.POSTGRES_PASSWORD,
    port: 5432,
    ssl: "disable"
  }
}];
process.stdout.write(JSON.stringify(data));
' | bash scripts/vm-kubectl.sh -n "$namespace" exec -i deployment/do14-main -- \
  n8n import:credentials --input=/dev/stdin --userId="$user_id"
unset password
