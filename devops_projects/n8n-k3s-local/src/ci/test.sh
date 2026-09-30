#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
main_url="${1:?Usage: test.sh <main_base_url>}"
: "${WEBHOOK_BASE_URL:?WEBHOOK_BASE_URL is required}"
namespace="${KUBE_NAMESPACE:-do14-helm}"
release="${HELM_RELEASE:?Set HELM_RELEASE to the temporary test release}"
if ! [[ "$namespace" == do14-helm && "$release" =~ ^do14-test-[a-z0-9]([a-z0-9-]*[a-z0-9])?$ ]] || (( ${#release} > 53 )); then
  echo 'Tests only modify temporary releases in do14-helm' >&2; exit 1
fi
[[ "$main_url" =~ ^http://127\.0\.0\.1:([0-9]+)$ ]] || { echo 'Use a localhost port-forward URL' >&2; exit 1; }
main_port="${BASH_REMATCH[1]}"
[[ "$WEBHOOK_BASE_URL" =~ ^http://127\.0\.0\.1:([0-9]+)$ ]] || { echo 'Use a localhost webhook port-forward URL' >&2; exit 1; }
webhook_port="${BASH_REMATCH[1]}"
temporary="$(mktemp -d)"
pids=()
cleanup() { for pid in "${pids[@]}"; do kill "$pid" 2>/dev/null || true; done; rm -rf -- "$temporary"; }
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
node --test tests/check-health.test.mjs
# n8n's CLI catch handler can log an error without a failing exit code.
kubectl -n "$namespace" exec -i "deployment/$release-main" -c n8n -- n8n import:workflow --input=/dev/stdin < tests/smoke-workflow.json | tee "$temporary/import.log"
grep -Fq 'Successfully imported 1 workflow.' "$temporary/import.log"
kubectl -n "$namespace" exec "deployment/$release-main" -c n8n -- n8n publish:workflow --id=DO14SmokeWorkflow | tee "$temporary/publish.log"
grep -Fq 'Please restart n8n for changes to take effect' "$temporary/publish.log"
# The CLI only changes the database; restart all readers before invoking webhooks.
for role in main webhook worker; do
  kubectl -n "$namespace" rollout restart "deployment/$release-$role"
done
for role in main webhook worker; do
  kubectl -n "$namespace" rollout status "deployment/$release-$role" --timeout=5m
done
kubectl -n "$namespace" port-forward --address=127.0.0.1 "service/$release-main" "$main_port:5678" > "$temporary/main.log" 2>&1 &
pids+=("$!")
kubectl -n "$namespace" port-forward --address=127.0.0.1 "service/$release-webhook" "$webhook_port:5678" > "$temporary/webhook.log" 2>&1 &
pids+=("$!")
for url in "$main_url" "$WEBHOOK_BASE_URL"; do
  ready=false
  for _ in {1..60}; do
    if curl --fail --silent --max-time 2 "$url/healthz/readiness" >/dev/null; then ready=true; break; fi
    sleep 1
  done
  "$ready" || { cat "$temporary"/*.log >&2; exit 1; }
done
newman run tests/n8n.postman_collection.json \
  --env-var "main_url=$main_url" --env-var "webhook_url=$WEBHOOK_BASE_URL" \
  --timeout-request 90000 --reporters cli,junit --reporter-junit-export "${TEST_REPORT:-artifacts/newman.xml}"
