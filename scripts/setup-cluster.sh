#!/bin/bash
set -e

# Navigate to repo root (adjust if needed)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

echo "Creating K3d cluster from configuration..."
k3d cluster create --config "${REPO_ROOT}/infrastructure/k3d/cluster.yaml"

echo "Installing local-path-provisioner for storage..."
kubectl apply -f /Users/devrishidas/Desktop/homelab/infrastructure/storage/local-path-provisioner/local-path-storage.yaml

echo "Setting local-path as default StorageClass..."
kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

echo "Cluster is ready!"
kubectl get nodes