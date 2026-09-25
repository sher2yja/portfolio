#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
if [[ -e .env ]]; then
  echo '.env уже существует; существующие ключи сохранены.'
  exit 0
fi

umask 077
temporary_env="$(mktemp .env.XXXXXX)"
trap 'rm -f "$temporary_env"' EXIT
{
  printf 'N8N_VERSION=2.40.6\n'
  printf 'N8N_ENCRYPTION_KEY=%s\n' "$(openssl rand -hex 32)"
  printf 'N8N_RUNNERS_AUTH_TOKEN=%s\n' "$(openssl rand -hex 32)"
  printf 'POSTGRES_PASSWORD=%s\n' "$(openssl rand -hex 32)"
} > "$temporary_env"
mv "$temporary_env" .env
trap - EXIT
echo '.env создан с правами только для владельца. Сохраните N8N_ENCRYPTION_KEY отдельно перед добавлением credentials.'
