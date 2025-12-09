#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
VALUES_DIR="$PROJECT_ROOT/values"

echo "Installing cert-manager..."

helm repo add jetstack https://charts.jetstack.io 2>/dev/null || true
helm repo update

helm upgrade --install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --values "$VALUES_DIR/cert-manager-values.yaml" \
  --wait \
  --timeout 5m

kubectl wait --namespace cert-manager \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/instance=cert-manager \
  --timeout=120s

echo ""
echo "cert-manager installed"
kubectl get pods -n cert-manager
