# Internal Developer Platform Demo

> An Internal Developer Platform showcasing progressive delivery, GitOps, and self-service workflows for Kubernetes

## Project Goals

This project demonstrates:
- **Self-service application onboarding** with golden path abstractions
- **Progressive delivery** using canary deployments with automated analysis
- **GitOps workflows** with ArgoCD
- **Observable deployments** with Prometheus metrics

## Quick Start

```bash
# 1. Bootstrap the entire platform
./scripts/bootstrap-platform.sh

# 2. Add local DNS entries
sudo ./scripts/setup-hosts.sh

# 3. Deploy the demo application
./scripts/deploy-demo-app.sh

# 4. Start background traffic (required — the canary analysis needs requests to measure)
#    The ingress routes on Host header; if port 80 isn't available, port-forward first:
#    kubectl port-forward svc/ingress-nginx-controller -n ingress-nginx 9191:80 &
#    Then adjust the URL below to http://localhost:9191
END=$((SECONDS + 600)); while [ $SECONDS -lt $END ]; do curl -s -o /dev/null -H "Host: demo-app-1.local" http://demo-app-1.local/; sleep 0.1; done &

# 5. Test a successful canary (v2 is healthy, will promote to 100%)
./scripts/trigger-rollout.sh v2

# 6. Test a failed canary (v2-bad has a 15% error rate, will auto-rollback)
./scripts/trigger-rollout.sh v2-bad
```

See [Local Setup Guide](docs/local-setup.md) for detailed instructions.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Platform Layer                            │
├─────────────────┬─────────────────┬─────────────────────────────┤
│    ArgoCD       │  Argo Rollouts  │   Prometheus + Grafana      │
│   (GitOps)      │   (Canary)      │      (Observability)        │
├─────────────────┴─────────────────┴─────────────────────────────┤
│                    Kubernetes (kind)                             │
│              ingress-nginx / 3 nodes                             │
└─────────────────────────────────────────────────────────────────┘
                              │
              ┌───────────────┼───────────────┐
              ▼               ▼               ▼
         App Config    Analysis Templates   Manifests
         (YAML)        (error-rate,        (Generated)
                        latency)
```

## Key Features

### 1. Simplified App Configuration

Developers define apps with a simple config:

```yaml
# applications/demo-app-1/app-config.yaml
spec:
  runtime:
    image: sample-service:v1
    port: 8080
  deployment:
    strategy: canary
    canary:
      steps:
        - weight: 33
          pause: 2m
        - weight: 66
          pause: 2m
      analysis:
        enabled: true
```

### 2. Automated Manifest Generation

```bash
./scripts/generate-manifests.sh applications/demo-app-1 demo
# Generates: Rollout, Services, Ingress, ServiceMonitor
```

### 3. Progressive Delivery with Auto-Rollback

Analysis templates automatically monitor deployments:
- **Error Rate**: Rolls back if >5% errors
- **Latency**: Rolls back if P95 >500ms

## Documentation

- [Local Setup Guide](docs/local-setup.md)
- [Architecture Overview](docs/architecture.md)
- [Developer Guide](docs/developer-guide.md)
- [Demo Scenarios](docs/demo.md)

## Tech Stack

| Component | Technology |
|-----------|------------|
| Kubernetes | kind (local) |
| GitOps | ArgoCD |
| Progressive Delivery | Argo Rollouts |
| Observability | Prometheus + Grafana |
| Ingress | nginx |
| Languages | Go, Bash, YAML |

## Project Status

- [x] Repository setup
- [x] Local Kubernetes cluster (kind)
- [x] ArgoCD installation
- [x] Argo Rollouts installation
- [x] Prometheus + Grafana
- [x] Demo application with metrics
- [x] Manifest generation scripts
- [x] Analysis templates (error-rate, latency)
- [x] Deployment automation
- [x] Canary deployment testing (error-rate and latency rollback validated)
- [x] Documentation (architecture, developer guide, demo scenarios)
- [ ] PR preview environments
- [ ] GitHub Actions integration

## Access URLs (Local)

| Service | URL |
|---------|-----|
| Demo App | http://demo-app-1.local |
| ArgoCD | http://argocd.local |
| Argo Rollouts | http://rollouts.local |
| Prometheus | http://prometheus.local |
| Grafana | http://grafana.local |

---
