# Local Platform Playground

Local Kubernetes platform on Docker Desktop for GitOps and cloud-native experimentation.

## What's Included

- **nginx-ingress** - Routes HTTP traffic to services via hostname
- **cert-manager** - TLS certificate management (required for Kargo)
- **ArgoCD** - GitOps continuous delivery
- **Kargo** - Promotion workflows for multi-environment deployments

All services run on Docker Desktop Kubernetes and are accessible via `*.local` domains.

## Prerequisites

- Docker Desktop with Kubernetes enabled
- kubectl
- Helm 3
- htpasswd (for password generation)

```bash
brew install kubectl helm
```

Enable Kubernetes in Docker Desktop: Settings → Kubernetes → Enable Kubernetes (Kubeadm)

## Quick Install

Install everything:

```bash
./scripts/install-all.sh
```

Or install individually:

```bash
./scripts/install-nginx-ingress.sh
./scripts/install-cert-manager.sh
./scripts/install-argocd.sh
./scripts/install-kargo.sh
```

## Configuration & Secrets

All Helm values are in `values/` directory:

```
values/
├── nginx-ingress-values.yaml
├── cert-manager-values.yaml
├── argocd-values.yaml
└── kargo-values.yaml
```

To customize, edit these files before running install scripts.

Get service credentials:

```bash
./scripts/get-passwords.sh
```

Default access:

- ArgoCD: http://argocd.local (admin / run get-passwords.sh)
- Kargo: http://kargo.local (admin / admin)

## Usage

Check installation status:

```bash
kubectl get pods -A
kubectl get ingress -A
```

Access services in browser:

- http://argocd.local
- http://kargo.local

View logs:

```bash
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server
kubectl logs -n kargo -l app.kubernetes.io/component=api
```

## Clean Start / Delete

Remove all components:

```bash
./scripts/clean-cluster.sh
```

This removes:
- All Helm releases
- CRDs and webhooks
- Namespaces
- Cluster-level resources

Then reinstall from scratch:

```bash
./scripts/install-all.sh
```

## Troubleshooting

**ArgoCD redirecting to HTTPS (307 error)**

ArgoCD must run in insecure mode. The values file includes `insecure: true` and `--insecure` flag. If still redirecting, reinstall:

```bash
./scripts/install-argocd.sh
```

**Kargo returns 400 or TLS handshake errors**

Kargo API runs with TLS internally. Ingress must use HTTPS backend. The values file has `backend-protocol: HTTPS`. If issues persist, patch ingress:

```bash
kubectl patch ingress kargo-api -n kargo --type=json \
  -p='[{"op": "replace", "path": "/metadata/annotations/nginx.ingress.kubernetes.io~1backend-protocol", "value": "HTTPS"}]'
```

**Kargo namespace stuck in "Terminating"**

Kargo uses CRDs with finalizers. The clean-cluster.sh script handles this, or manually:

```bash
kubectl get namespace kargo -o json | \
  jq '.spec.finalizers = []' | \
  kubectl replace --raw /api/v1/namespaces/kargo/finalize -f -
```

**Services not accessible**

Check /etc/hosts has entries:

```bash
grep -E "argocd.local|kargo.local" /etc/hosts
```

Should show: `127.0.0.1 argocd.local kargo.local`

Verify ingress controller is running:

```bash
kubectl get svc -n ingress-nginx
```

**LoadBalancer stuck in PENDING**

Docker Desktop Kubernetes should automatically assign localhost. If stuck, restart Docker Desktop.

**Pods not starting**

Increase Docker Desktop resources: Settings → Resources → 4 CPU, 8GB RAM minimum.