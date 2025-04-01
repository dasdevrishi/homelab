#!/bin/bash
set -e

# Navigate to repo root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# Add Prometheus community Helm repo
echo "Adding Prometheus community Helm repo..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Create monitoring namespace
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

# Install kube-prometheus-stack
echo "Installing Prometheus stack..."
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --values "${REPO_ROOT}/monitoring/prometheus-stack/values.yaml" \
  --wait

echo "Monitoring stack has been installed!"
echo "Grafana URL: http://localhost:30080"
echo "Default username: admin"
echo "Default password: Dev5rishi"

# Get Grafana admin password if it was randomly generated
if grep -q "adminPassword" "${REPO_ROOT}/monitoring/prometheus-stack/values.yaml"; then
  echo "Using password from values.yaml"
else
  echo "Randomly generated admin password:"
  kubectl get secret --namespace monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode
fi