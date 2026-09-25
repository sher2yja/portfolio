#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd)"
cd "$project_dir"

app_ip="$(vagrant ssh-config < /dev/null | awk '$1 == "HostName" {print $2; exit}')"
test -n "$app_ip"

bash scripts/vm-kubectl.sh create namespace do14-production --dry-run=client -o yaml |
  bash scripts/vm-kubectl.sh apply -f -
bash scripts/vm-kubectl.sh apply -f runner/deploy-rbac.yaml

# Сервисный токен хранится только в Kubernetes Secret и kubeconfig runner-VM.
if ! bash scripts/vm-kubectl.sh -n do14-helm get secret do14-deployer-token >/dev/null 2>&1; then
  printf '%s\n' \
    'apiVersion: v1' \
    'kind: Secret' \
    'metadata:' \
    '  name: do14-deployer-token' \
    '  namespace: do14-helm' \
    '  annotations:' \
    '    kubernetes.io/service-account.name: do14-deployer' \
    'type: kubernetes.io/service-account-token' |
    bash scripts/vm-kubectl.sh apply -f -
fi

token_b64=''
for _ in 1 2 3 4 5; do
  token_b64="$(bash scripts/vm-kubectl.sh -n do14-helm get secret do14-deployer-token -o jsonpath='{.data.token}')"
  test -n "$token_b64" && break
  sleep 1
done
test -n "$token_b64"

ca_b64="$(vagrant ssh -c 'sudo k3s kubectl config view --raw -o jsonpath="{.clusters[0].cluster.certificate-authority-data}"' < /dev/null | tr -d '\r')"
test -n "$ca_b64"

temporary_kubeconfig="$(mktemp)"
trap 'rm -f "$temporary_kubeconfig"' EXIT
chmod 600 "$temporary_kubeconfig"
printf 'apiVersion: v1\nkind: Config\nclusters:\n- name: do14\n  cluster:\n    certificate-authority-data: %s\n    server: https://%s:6443\nusers:\n- name: do14-deployer\n  user:\n    token: %s\ncontexts:\n- name: do14\n  context:\n    cluster: do14\n    user: do14-deployer\n    namespace: do14-helm\ncurrent-context: do14\n' \
  "$ca_b64" "$app_ip" "$(printf '%s' "$token_b64" | base64 -d)" > "$temporary_kubeconfig"

cd "$project_dir/runner"
vagrant ssh -c 'mkdir -p ~/.kube && chmod 700 ~/.kube' < /dev/null
vagrant upload "$temporary_kubeconfig" /home/vagrant/.kube/config
vagrant ssh -c 'chmod 600 ~/.kube/config && kubectl auth can-i create deployments -n do14-helm && kubectl auth can-i create deployments -n do14-production && ! kubectl auth can-i get secrets -n kube-system' < /dev/null
