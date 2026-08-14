#!/bin/bash
# deploy-app.sh — автоматический деплой аддонов и манифестов приложения
# Запускается на хосте, подключается к master (192.168.33.10) по SSH.

set -euo pipefail

MASTER_IP="192.168.33.10"
SSH_KEY=".vagrant/machines/master/libvirt/private_key"
SSH_OPTS="-i ${SSH_KEY} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR"
SSH_USER="vagrant"

echo "============================================"
echo "  Auto-deploy: addons + application manifests"
echo "  Target: master@${MASTER_IP}"
echo "============================================"

# Декоратор: выполнить команду на master через SSH.
run_on_master() {
    ssh ${SSH_OPTS} ${SSH_USER}@${MASTER_IP} "bash -s" <<< "$1"
}

# Базовая команда для kubectl, чтобы не писать export каждый раз
KUBECTL="export KUBECONFIG=/home/vagrant/.kube/config && kubectl"

echo ""
echo "[1/6] Waiting for all 3 nodes to register and become Ready..."
run_on_master "
${KUBECTL} get nodes --no-headers
until [ \"\$(${KUBECTL} get nodes --no-headers | grep -c 'Ready')\" -ge 3 ]; do 
    echo '  -> Waiting for nodes...'
    sleep 3
done
${KUBECTL} wait --for=condition=Ready node --all --timeout=300s
echo '  -> All nodes Ready'
"

echo ""
echo "[2/6] Installing ingress-nginx (LoadBalancer)..."
run_on_master "
${KUBECTL} apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml
${KUBECTL} wait --namespace ingress-nginx --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller --timeout=300s
echo '  -> ingress-nginx Ready'
"

echo ""
echo "[3/6] Installing cert-manager..."
run_on_master "
${KUBECTL} apply -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.yaml
${KUBECTL} wait --namespace cert-manager --for=condition=ready pod \
  --selector=app.kubernetes.io/instance=cert-manager --timeout=300s
echo '  -> cert-manager Ready'
"

echo ""
echo "[4/6] Applying application manifests..."
run_on_master "
${KUBECTL} apply -f /vagrant/k3s/manifests/namespace.yaml
${KUBECTL} apply -f /vagrant/k3s/pv.yaml
${KUBECTL} apply -f /vagrant/k3s/pvc.yaml
${KUBECTL} apply -f /vagrant/k3s/manifests/configmap.yaml
${KUBECTL} apply -f /vagrant/k3s/manifests/secrets.yaml
${KUBECTL} apply -f /vagrant/k3s/manifests/services.yaml
${KUBECTL} apply -f /vagrant/k3s/issuer.yaml
${KUBECTL} apply -f /vagrant/k3s/manifests/deployments.yaml
${KUBECTL} apply -f /vagrant/k3s/certificate.yaml
${KUBECTL} apply -f /vagrant/k3s/ingress.yaml
echo '  -> All manifests applied'
"

echo ""
echo "[5/6] Waiting for application pods to be Ready (pull may take time)..."
run_on_master "
# Ждем, пока появится хотя бы 1 под, чтобы kubectl wait не падал сразу
until [ \"\$(${KUBECTL} get pods -n basic-kuber --no-headers 2>/dev/null | wc -l)\" -ge 1 ]; do 
    echo '  -> Waiting for pods to be created...'
    sleep 3
done
${KUBECTL} wait --namespace basic-kuber --for=condition=ready pod --all --timeout=600s
echo '  -> All pods Ready'
"

echo ""
echo "[6/6] Cluster status:"
run_on_master "
echo '--- Nodes ---'
${KUBECTL} get nodes
echo ''
echo '--- Pods (basic-kuber) ---'
${KUBECTL} get pods -n basic-kuber
echo ''
echo '--- Ingress ---'
${KUBECTL} get ingress -n basic-kuber
echo ''
echo '--- Certificate ---'
${KUBECTL} get certificate -n basic-kuber
"

echo ""
echo "============================================"
echo "  Auto-deploy complete!"
echo "  Wait for Spring Boot services to finish starting:"
echo "  ./scripts/checksvc.sh"
echo "============================================"