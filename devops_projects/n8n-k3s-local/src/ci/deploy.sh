#!/usr/bin/env bash
set -euo pipefail
set +x
cd "$(dirname "$0")/.."
case "${1:-}" in
  staging) namespace=do14-helm ;;
  production) namespace=do14-production ;;
  *) echo 'Usage: deploy.sh <staging|production>' >&2; exit 1 ;;
esac
[[ "${KUBE_NAMESPACE:-$namespace}" == "$namespace" ]] || { echo 'KUBE_NAMESPACE does not match target' >&2; exit 1; }
release="${HELM_RELEASE:-do14}"
if ! [[ "$release" == do14 || "$release" =~ ^do14-test-[a-z0-9]([a-z0-9-]*[a-z0-9])?$ ]] || (( ${#release} > 53 )); then
  echo 'Invalid release' >&2; exit 1
fi
for name in REGISTRY IMAGE_TAG N8N_ENCRYPTION_KEY N8N_RUNNERS_AUTH_TOKEN POSTGRES_PASSWORD PULL_USER PULL_TOKEN; do
  [[ -n "${!name:-}" && "${!name}" != *CHANGE_ME* && "${!name}" != *$'\n'* && "${!name}" != *$'\r'* ]] || { echo "$name is required and must be a single line" >&2; exit 1; }
done
[[ "$REGISTRY" =~ ^[a-z0-9][a-z0-9.:-]*/[a-z0-9][a-z0-9._/-]*$ && "$REGISTRY" != *..* && "$REGISTRY" != */ ]]
[[ "$IMAGE_TAG" =~ ^[A-Za-z0-9_][A-Za-z0-9_.-]{0,127}$ ]]
kubectl -n "$namespace" get services >/dev/null
secret=n8n-secrets
[[ "$release" == do14 ]] || secret="$release-secrets"
pull_secret="$release-registry"
# Refuse to rotate database/encryption credentials on an existing installation.
if kubectl -n "$namespace" get secret "$secret" >/dev/null 2>&1; then
  for name in N8N_ENCRYPTION_KEY N8N_RUNNERS_AUTH_TOKEN POSTGRES_PASSWORD; do
    existing="$(kubectl -n "$namespace" get secret "$secret" -o "jsonpath={.data.$name}" | base64 -d)"
    [[ "$existing" == "${!name}" ]] || { echo "Refusing to replace existing $name; rotate explicitly" >&2; exit 1; }
  done
fi
umask 077
temporary="$(mktemp -d)"
forward_pid=''
cleanup() {
  [[ -z "$forward_pid" ]] || kill "$forward_pid" 2>/dev/null || true
  rm -rf -- "$temporary"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
for name in N8N_ENCRYPTION_KEY N8N_RUNNERS_AUTH_TOKEN POSTGRES_PASSWORD; do
  printf '%s=%s\n' "$name" "${!name}" >> "$temporary/secrets.env"
done
kubectl -n "$namespace" create secret generic "$secret" --from-env-file="$temporary/secrets.env" --dry-run=client -o yaml | kubectl apply -f - >/dev/null
# Credentials are written privately, never placed in process arguments or Helm values.
export REGISTRY PULL_USER PULL_TOKEN
node -e 'const p=process.env; process.stdout.write(JSON.stringify({auths:{[p.REGISTRY.split("/")[0]]:{auth:Buffer.from(p.PULL_USER+":"+p.PULL_TOKEN).toString("base64")}}}));' > "$temporary/config.json"
kubectl -n "$namespace" create secret generic "$pull_secret" --type=kubernetes.io/dockerconfigjson --from-file=.dockerconfigjson="$temporary/config.json" --dry-run=client -o yaml | kubectl apply -f - >/dev/null
args=(--set-string "existingSecret=$secret" --set-string "imagePullSecrets[0].name=$pull_secret" --set-string "images.tag=$IMAGE_TAG")
for role in main webhook worker runner; do args+=(--set-string "images.$role=$REGISTRY/$role"); done
if [[ "$release" != do14 ]]; then
  args+=(--set service.type=ClusterIP --set postgres.storage=1Gi --set redis.storage=256Mi)
fi
helm upgrade --install "$release" chart -n "$namespace" -f "chart/values-$1.yaml" "${args[@]}" --atomic --wait --timeout "${HELM_TIMEOUT:-10m}"
for role in main webhook; do
  : > "$temporary/$role.log"
  kubectl -n "$namespace" port-forward --address=127.0.0.1 "service/$release-$role" :5678 > "$temporary/$role.log" 2>&1 &
  forward_pid=$!
  port=''
  for _ in {1..60}; do
    port="$(sed -n 's/^Forwarding from 127.0.0.1:\([0-9]*\) ->.*/\1/p' "$temporary/$role.log" | head -1)"
    [[ -z "$port" ]] || break
    kill -0 "$forward_pid" 2>/dev/null || { cat "$temporary/$role.log" >&2; exit 1; }
    sleep 1
  done
  test -n "$port"
  curl --fail --silent --show-error --max-time 15 "http://127.0.0.1:$port/healthz/readiness"
  kill "$forward_pid"
  wait "$forward_pid" 2>/dev/null || true
  forward_pid=''
done
