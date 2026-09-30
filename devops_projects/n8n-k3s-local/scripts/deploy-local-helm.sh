#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
case "${1:-do14-helm}" in
  do14-helm) target=staging ;;
  do14-production) target=production ;;
  *) echo 'Use do14-helm or do14-production; CI deploy selects fixed namespaces' >&2; exit 1 ;;
esac
if (( $# > 1 )); then
  echo 'Custom values are no longer accepted; use src/ci/deploy.sh' >&2; exit 1
fi
bash scripts/vm-kubectl.sh -- bash src/ci/deploy.sh "$target"
