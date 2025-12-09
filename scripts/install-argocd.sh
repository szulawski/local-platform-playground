#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
VALUES_DIR="$PROJECT_ROOT/values"

echo "Installing ArgoCD..."

# Uninstall if exists
if helm list -n argocd | grep -q argocd; then
  echo "Uninstalling existing ArgoCD..."
  helm uninstall argocd -n argocd
  kubectl delete namespace argocd --wait=false 2>/dev/null || true
  sleep 5
fi

helm repo add argo https://argoproj.github.io/argo-helm 2>/dev/null || true
helm repo update

helm install argocd argo/argo-cd \
  --namespace argocd \
  --create-namespace \
  --values "$VALUES_DIR/argocd-values.yaml" \
  --wait \
  --timeout 5m

kubectl wait --namespace argocd \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/name=argocd-server \
  --timeout=120s

echo ""
echo "ArgoCD installed"
echo "URL: http://argocd.local"
echo "User: admin"
echo "Password: Run ./get-passwords.sh"
