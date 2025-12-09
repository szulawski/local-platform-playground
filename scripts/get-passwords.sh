#!/bin/bash

set -e

echo "Service Credentials"
echo "==================="
echo ""

if kubectl get namespace argocd &> /dev/null; then
  echo "ArgoCD:"
  echo "  URL:      http://argocd.local"
  echo "  Username: admin"
  if kubectl get secret argocd-initial-admin-secret -n argocd &> /dev/null; then
    PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
    echo "  Password: $PASSWORD"
  else
    echo "  Password: (not ready yet)"
  fi
else
  echo "ArgoCD: Not installed"
fi

echo ""

if kubectl get namespace kargo &> /dev/null; then
  echo "Kargo:"
  echo "  URL:      http://kargo.local"
  echo "  Username: admin"
  echo "  Password: admin"
else
  echo "Kargo: Not installed"
fi

echo ""
