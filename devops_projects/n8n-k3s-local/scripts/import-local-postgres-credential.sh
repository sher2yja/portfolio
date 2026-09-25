#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
if [[ ! -f .env ]]; then
  echo 'Сначала создайте .env.' >&2
  exit 1
fi
password="$(awk -F= '$1 == "POSTGRES_PASSWORD" {print $2; exit}' .env)"
if [[ -z "$password" ]] || [[ "$password" == *CHANGE_ME* ]]; then
  echo 'POSTGRES_PASSWORD не задан.' >&2
  exit 1
fi
user_id="$(bash scripts/vm-kubectl.sh -n do14-helm exec do14-postgres-0 -- \
  psql -U n8n -d n8n -tAc 'select id from "user" limit 1')"
if [[ -z "$user_id" ]]; then
  echo 'В n8n ещё не создан владелец.' >&2
  exit 1
fi

# JSON идёт напрямую в CLI; пароль не попадает в аргументы процесса или Git.
POSTGRES_PASSWORD="$password" node -e '
const data = [{
  id: "DO14PgCredential",
  name: "DO14 local PostgreSQL",
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
' | bash scripts/vm-kubectl.sh -n do14-helm exec -i deployment/do14-main -- \
  n8n import:credentials --input=/dev/stdin --userId="$user_id"
unset password
