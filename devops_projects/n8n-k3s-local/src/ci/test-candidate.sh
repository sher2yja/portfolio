#!/usr/bin/env bash
set -euo pipefail
set +x
cd "$(dirname "$0")/.."
: "${REGISTRY:?REGISTRY is required}"
: "${IMAGE_TAG:?IMAGE_TAG is required}"
for tool in kubectl helm node newman curl openssl; do command -v "$tool" >/dev/null; done
export KUBE_NAMESPACE=do14-helm
umask 077
temporary="$(mktemp -d)"
HELM_RELEASE="do14-test-$(date +%s)-$$"
export HELM_RELEASE
artifacts="${ARTIFACT_DIR:-$PWD/artifacts/$HELM_RELEASE}"
mkdir -p "$artifacts"
export TEST_REPORT="$artifacts/newman.xml"
pids=()
diagnostics() {
  # Preserve snapshots before Helm --atomic can remove a failed installation.
  selector="app.kubernetes.io/instance=$HELM_RELEASE"
  kubectl --request-timeout=10s -n "$KUBE_NAMESPACE" get pods -l "$selector" -o wide >> "$artifacts/pods.txt" 2>&1 || true
  kubectl --request-timeout=10s -n "$KUBE_NAMESPACE" get events --field-selector type=Warning >> "$artifacts/warnings.txt" 2>&1 || true
  for role in main webhook worker; do
    kubectl --request-timeout=10s -n "$KUBE_NAMESPACE" logs "deployment/$HELM_RELEASE-$role" -c n8n --tail=150 >> "$artifacts/$role.log" 2>&1 || true
  done
  kubectl --request-timeout=10s -n "$KUBE_NAMESPACE" logs "deployment/$HELM_RELEASE-worker" -c task-runner --tail=150 >> "$artifacts/task-runner.log" 2>&1 || true
}
cleanup() {
  code=$?
  trap - EXIT
  for pid in "${pids[@]}"; do kill "$pid" 2>/dev/null || true; done
  diagnostics
  # Only this generated release and its explicit PVC names are disposable.
  helm uninstall "$HELM_RELEASE" -n "$KUBE_NAMESPACE" --ignore-not-found --wait --timeout 2m || code=1
  kubectl -n "$KUBE_NAMESPACE" delete pods -l "app.kubernetes.io/instance=$HELM_RELEASE" --ignore-not-found --wait=true --timeout=2m || code=1
  kubectl -n "$KUBE_NAMESPACE" delete pvc "data-$HELM_RELEASE-postgres-0" "data-$HELM_RELEASE-redis-0" --ignore-not-found --wait=true --timeout=2m || code=1
  kubectl -n "$KUBE_NAMESPACE" delete secret "$HELM_RELEASE-secrets" "$HELM_RELEASE-registry" --ignore-not-found || code=1
  rm -rf -- "$temporary"
  exit "$code"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
N8N_ENCRYPTION_KEY="$(openssl rand -hex 32)"
N8N_RUNNERS_AUTH_TOKEN="$(openssl rand -hex 32)"
POSTGRES_PASSWORD="$(openssl rand -hex 32)"
export N8N_ENCRYPTION_KEY N8N_RUNNERS_AUTH_TOKEN POSTGRES_PASSWORD
export PULL_USER="${PULL_USER:-${REGISTRY_USER:-}}"
export PULL_TOKEN="${PULL_TOKEN:-${REGISTRY_PASSWORD:-}}"
# Keep startup diagnostics even when atomic installation rolls back on timeout.
(while sleep 15; do diagnostics; done) &
pids+=("$!")
bash ci/deploy.sh staging
urls=()
for role in main webhook; do
  kubectl -n "$KUBE_NAMESPACE" port-forward --address=127.0.0.1 "service/$HELM_RELEASE-$role" :5678 > "$temporary/$role.log" 2>&1 &
  pids+=("$!")
  port=''
  for _ in {1..60}; do
    port="$(sed -n 's/^Forwarding from 127.0.0.1:\([0-9]*\) ->.*/\1/p' "$temporary/$role.log" | head -1)"
    [[ -z "$port" ]] || break
    kill -0 "${pids[-1]}" 2>/dev/null || { cat "$temporary/$role.log" >&2; exit 1; }
    sleep 1
  done
  test -n "$port"
  urls+=("http://127.0.0.1:$port")
done
# Bootstrap only the fresh disposable database, never an existing user's owner.
TEST_OWNER_PASSWORD="Aa1!$(openssl rand -hex 24)"
export TEST_OWNER_PASSWORD
node -e 'process.stdout.write(JSON.stringify({email:"smoke@example.test",firstName:"CI",lastName:"Smoke",password:process.env.TEST_OWNER_PASSWORD}));' > "$temporary/owner.json"
curl --fail --silent --show-error --max-time 30 -H 'Content-Type: application/json' --data-binary "@$temporary/owner.json" "${urls[0]}/rest/owner/setup" >/dev/null
unset TEST_OWNER_PASSWORD
for pid in "${pids[@]}"; do kill "$pid"; wait "$pid" 2>/dev/null || true; done
pids=()
export WEBHOOK_BASE_URL="${urls[1]}"
bash ci/test.sh "${urls[0]}"
