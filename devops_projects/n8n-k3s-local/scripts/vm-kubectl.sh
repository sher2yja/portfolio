#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
vm_address="$(vagrant ssh-config < /dev/null | awk '$1 == "HostName" {print $2; exit}')"
if [[ -z "$vm_address" ]]; then
  echo 'Не удалось получить адрес локальной VM.' >&2
  exit 1
fi

temporary_kubeconfig="$(mktemp)"
trap 'rm -f "$temporary_kubeconfig"' EXIT
chmod 600 "$temporary_kubeconfig"
vagrant ssh -c 'sudo cat /etc/rancher/k3s/k3s.yaml' < /dev/null > "$temporary_kubeconfig"
sed -i "s#https://127.0.0.1:6443#https://${vm_address}:6443#" "$temporary_kubeconfig"
if [[ "${1:-}" == -- ]]; then
  shift
  KUBECONFIG="$temporary_kubeconfig" "$@"
else
  kubectl --kubeconfig "$temporary_kubeconfig" "$@"
fi
