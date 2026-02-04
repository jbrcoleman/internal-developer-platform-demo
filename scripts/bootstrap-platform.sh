#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Platform Demo - Full Bootstrap${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"
command -v kind >/dev/null 2>&1 || { echo -e "${RED}kind is required but not installed${NC}"; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo -e "${RED}kubectl is required but not installed${NC}"; exit 1; }
command -v helm >/dev/null 2>&1 || { echo -e "${RED}helm is required but not installed${NC}"; exit 1; }
echo -e "${GREEN}All prerequisites found${NC}"
echo ""

# Step 1: Create cluster
echo -e "${YELLOW}Step 1/6: Creating kind cluster...${NC}"
./scripts/create-cluster.sh
echo ""

# Step 2: Install ingress-nginx
echo -e "${YELLOW}Step 2/6: Installing ingress-nginx...${NC}"
./platform-config/bootstrap/ingress-nginx/install.sh
echo ""

# Step 3: Install ArgoCD
echo -e "${YELLOW}Step 3/6: Installing ArgoCD...${NC}"
./platform-config/bootstrap/argocd/install.sh
echo ""

# Step 4: Install Argo Rollouts
echo -e "${YELLOW}Step 4/6: Installing Argo Rollouts...${NC}"
./platform-config/bootstrap/argo-rollouts/install.sh
echo ""

# Step 5: Install Prometheus
echo -e "${YELLOW}Step 5/6: Installing Prometheus stack...${NC}"
./platform-config/bootstrap/prometheus/install.sh
echo ""

# Step 6: Build and load demo app images
echo -e "${YELLOW}Step 6/6: Building demo application images...${NC}"
cd demo-apps/sample-service

echo "  Building v1..."
docker build -t sample-service:v1 --build-arg APP_VERSION=v1 . -q
kind load docker-image sample-service:v1 --name platform-demo

echo "  Building v2..."
docker build -t sample-service:v2 --build-arg APP_VERSION=v2 . -q
kind load docker-image sample-service:v2 --name platform-demo

echo "  Building v2-bad (high error rate)..."
docker build -t sample-service:v2-bad --build-arg APP_VERSION=v2-bad . -q
kind load docker-image sample-service:v2-bad --name platform-demo

echo "  Building v3-slow (high latency)..."
docker build -t sample-service:v3-slow --build-arg APP_VERSION=v3-slow . -q
kind load docker-image sample-service:v3-slow --name platform-demo

cd ../..
echo -e "${GREEN}Demo images loaded into cluster${NC}"
echo ""

# Print summary
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}Platform bootstrap complete!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${YELLOW}Access URLs (add to /etc/hosts if not already):${NC}"
echo "  ArgoCD:       http://argocd.local"
echo "  Rollouts:     http://rollouts.local"
echo "  Prometheus:   http://prometheus.local"
echo "  Grafana:      http://grafana.local"
echo ""
echo -e "${YELLOW}ArgoCD Credentials:${NC}"
echo "  Username: admin"
echo -n "  Password: "
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>/dev/null | base64 -d || echo "(secret not ready yet)"
echo ""
echo ""
echo -e "${YELLOW}Grafana Credentials:${NC}"
echo "  Username: admin"
echo -n "  Password: "
kubectl get secret -n monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" 2>/dev/null | base64 -d || echo "prom-operator"
echo ""
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Add hosts entries: sudo ./scripts/setup-hosts.sh"
echo "  2. Deploy demo app:   ./scripts/deploy-demo-app.sh"
echo ""
