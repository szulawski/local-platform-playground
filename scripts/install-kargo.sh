#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
VALUES_DIR="$PROJECT_ROOT/values"

echo "Installing Kargo..."

# Uninstall if exists
if helm list -n kargo | grep -q kargo; then
  echo "Uninstalling existing Kargo..."
  helm uninstall kargo -n kargo
  kubectl delete namespace kargo --wait=false 2>/dev/null || true
  sleep 5
fi

# Generate credentials
PASSWORD_HASH=$(htpasswd -bnBC 10 "" admin | tr -d ':\n')
TOKEN_KEY=$(openssl rand -base64 32)

# Install fresh
helm install kargo oci://ghcr.io/akuity/kargo-charts/kargo \
  --version 1.8.4 \
  --namespace kargo \
  --create-namespace \
  --values "$VALUES_DIR/kargo-values.yaml" \
  --set "api.adminAccount.passwordHash=$PASSWORD_HASH" \
  --set "api.adminAccount.tokenSigningKey=$TOKEN_KEY" \
  --wait \
  --timeout 5m

kubectl wait --namespace kargo \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=api \
  --timeout=120s

echo ""
echo "Kargo installed"
echo "URL: http://kargo.local"
echo "User: admin"
echo "Password: admin"
