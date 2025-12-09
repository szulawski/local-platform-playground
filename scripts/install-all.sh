#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing Local Platform Playground..."
echo ""

# Check prerequisites
command -v kubectl >/dev/null 2>&1 || { echo "kubectl required"; exit 1; }
command -v helm >/dev/null 2>&1 || { echo "helm required"; exit 1; }
command -v htpasswd >/dev/null 2>&1 || { echo "htpasswd required"; exit 1; }
kubectl cluster-info >/dev/null 2>&1 || { echo "Kubernetes cluster not accessible"; exit 1; }

# Configure /etc/hosts
echo "Configuring /etc/hosts..."
if grep -q "argocd.local" /etc/hosts 2>/dev/null && grep -q "kargo.local" /etc/hosts 2>/dev/null; then
  echo "  Already configured"
else
  echo "127.0.0.1 argocd.local kargo.local" | sudo tee -a /etc/hosts >/dev/null
  echo "  Added entries"
fi
echo ""

# Install components
"$SCRIPT_DIR/install-nginx-ingress.sh"
echo ""

"$SCRIPT_DIR/install-cert-manager.sh"
echo ""

"$SCRIPT_DIR/install-argocd.sh"
echo ""

"$SCRIPT_DIR/install-kargo.sh"
echo ""

echo "=========================================="
echo "Installation complete!"
echo "=========================================="
echo ""
echo "ArgoCD:  http://argocd.local"
echo "  User:  admin"
echo "  Pass:  Run ./get-passwords.sh"
echo ""
echo "Kargo:   http://kargo.local"
echo "  User:  admin"
echo "  Pass:  admin"
echo ""
echo "To remove: ./clean-cluster.sh"
echo "=========================================="
