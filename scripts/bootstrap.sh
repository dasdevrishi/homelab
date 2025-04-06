# scripts/bootstrap.sh
#!/bin/bash
set -e

echo "Setting up ArgoCD..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "Waiting for ArgoCD to be ready..."
kubectl wait --for=condition=available deployment/argocd-server -n argocd --timeout=300s

echo "Deploying bootstrap applications..."
kubectl apply -f bootstrap/applications/

echo "Setup complete! Access ArgoCD UI with:"
echo "kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo "Username: admin"
echo "Password: $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)"