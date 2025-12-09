#!/bin/bash

set -e

echo "Cleaning entire platform from cluster..."
echo ""

# Function to completely remove a namespace
delete_namespace() {
  local ns=$1
  echo "Removing namespace: $ns"
  
  if ! kubectl get namespace "$ns" &> /dev/null; then
    echo "  Already deleted"
    return 0
  fi
  
  # Force delete all pods first
  echo "  Force deleting pods..."
  kubectl delete pods --all -n "$ns" --force --grace-period=0 2>/dev/null || true
  
  # Delete the namespace
  echo "  Deleting namespace..."
  kubectl delete namespace "$ns" --timeout=10s 2>/dev/null || true
  
  # If still exists, force finalize
  if kubectl get namespace "$ns" &> /dev/null; then
    echo "  Force finalizing..."
    kubectl get namespace "$ns" -o json | \
      jq '.spec.finalizers = []' | \
      kubectl replace --raw /api/v1/namespaces/$ns/finalize -f - 2>/dev/null || true
  fi
  
  # Wait for deletion
  local count=0
  while kubectl get namespace "$ns" &> /dev/null && [ $count -lt 30 ]; do
    sleep 1
    ((count++))
  done
  
  if kubectl get namespace "$ns" &> /dev/null; then
    echo "  WARNING: Still exists after 30s"
  else
    echo "  Deleted"
  fi
  echo ""
}

# Uninstall Helm releases
echo "Uninstalling Helm releases..."
helm list -A -q 2>/dev/null | while read release; do
  if [ -n "$release" ]; then
    ns=$(helm list -A | grep "^$release" | awk '{print $2}')
    echo "  $release (namespace: $ns)"
    helm uninstall "$release" -n "$ns" --wait --timeout=30s 2>/dev/null || true
  fi
done
echo ""

# Delete webhooks (before CRDs!)
echo "Deleting webhooks..."
kubectl delete validatingwebhookconfigurations --all 2>/dev/null || true
kubectl delete mutatingwebhookconfigurations --all 2>/dev/null || true
echo ""

# Delete CRDs
echo "Deleting CRDs..."
kubectl get crd -o name 2>/dev/null | grep -E "kargo|argo|cert-manager" | xargs -r kubectl delete 2>/dev/null || true
echo ""

# Delete namespaces
delete_namespace "kargo"
delete_namespace "argocd"
delete_namespace "cert-manager"
delete_namespace "ingress-nginx"

# Clean cluster resources
echo "Cleaning cluster-level resources..."
for name in kargo argocd cert-manager ingress-nginx; do
  kubectl delete clusterroles -l app.kubernetes.io/name=$name 2>/dev/null || true
  kubectl delete clusterrolebindings -l app.kubernetes.io/name=$name 2>/dev/null || true
done
echo ""

# Clean /etc/hosts
echo "Cleaning /etc/hosts..."
if grep -q "argocd.local\|kargo.local" /etc/hosts 2>/dev/null; then
  sudo sed -i '' '/argocd.local/d; /kargo.local/d' /etc/hosts 2>/dev/null || true
  echo "  Cleaned"
else
  echo "  Already clean"
fi

echo ""
echo "Cleanup complete!"
