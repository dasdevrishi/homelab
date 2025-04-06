#!/bin/bash
set -e

# Navigate to repo root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# Create argocd namespace
echo "Creating ArgoCD namespace..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

# Install ArgoCD
echo "Installing ArgoCD..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD pods to be ready
echo "Waiting for ArgoCD to be ready..."
kubectl rollout status deployment argocd-server -n argocd --timeout=300s

# Get ArgoCD admin password
echo "Fetching ArgoCD admin password..."
ARGOCD_PASSWORD=$(kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 --decode)

# Get ArgoCD NodePort
#ARGOCD_PORT=$(kubectl get svc argocd-server -n argocd -o jsonpath='{.spec.ports[0].nodePort}')

# Display ArgoCD access information
echo "ArgoCD has been installed!"
echo "Access the ArgoCD UI: https://localhost:8080"
echo "Admin username: admin"
echo "Admin password: ${ARGOCD_PASSWORD}"

echo "Login via CLI with:"
echo "  argocd login localhost:8080 --username admin --password ${ARGOCD_PASSWORD} --insecure"

# Forward the ArgoCD server port to access the UI
echo "Forward the ArgoCD server port to access the UI"
kubectl port-forward svc/argocd-server -n argocd 8080:443
