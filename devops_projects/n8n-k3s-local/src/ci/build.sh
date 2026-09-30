#!/usr/bin/env bash
set -euo pipefail
set +x
cd "$(dirname "$0")/.."
for name in REGISTRY REGISTRY_USER REGISTRY_PASSWORD IMAGE_TAG; do
  [[ -n "${!name:-}" && "${!name}" != *CHANGE_ME* ]] || { echo "$name is required" >&2; exit 1; }
done
[[ "$REGISTRY" =~ ^[a-z0-9][a-z0-9.:-]*/[a-z0-9][a-z0-9._/-]*$ && "$REGISTRY" != *..* && "$REGISTRY" != */ ]] || { echo 'REGISTRY must be a lowercase registry/path without scheme' >&2; exit 1; }
[[ "$IMAGE_TAG" =~ ^[A-Za-z0-9_][A-Za-z0-9_.-]{0,127}$ ]] || { echo 'Invalid IMAGE_TAG' >&2; exit 1; }
version="$(sed -n 's/^appVersion: "\([^"]*\)".*/\1/p' chart/Chart.yaml)"
test -n "$version"
docker info >/dev/null
umask 077
export DOCKER_CONFIG
DOCKER_CONFIG="$(mktemp -d)"
trap 'rm -rf -- "$DOCKER_CONFIG"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
printf '%s' "$REGISTRY_PASSWORD" | docker login "${REGISTRY%%/*}" -u "$REGISTRY_USER" --password-stdin
for role in main webhook worker runner; do
  docker build --build-arg "N8N_VERSION=$version" -f "dockerfiles/$role/Dockerfile" -t "$REGISTRY/$role:$IMAGE_TAG" .
  actual="$(docker image inspect "$REGISTRY/$role:$IMAGE_TAG" --format '{{index .Config.Labels "org.opencontainers.image.version"}}')"
  [[ "$actual" == "$version" ]]
  if [[ "$role" != runner ]]; then
    docker run --rm --entrypoint n8n "$REGISTRY/$role:$IMAGE_TAG" --version | grep -Fx "$version"
    docker run --rm --entrypoint sh "$REGISTRY/$role:$IMAGE_TAG" -c 'test ! -e /usr/bin/ssh && test ! -e /usr/bin/scp && test ! -e /usr/bin/sftp'
  fi
  docker push "$REGISTRY/$role:$IMAGE_TAG"
done
