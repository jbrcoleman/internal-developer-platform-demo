#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Deploying Demo Application${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if cluster exists
if ! kubectl cluster-info &>/dev/null; then
    echo -e "${RED}No Kubernetes cluster found. Run ./scripts/bootstrap-platform.sh first${NC}"
    exit 1
fi

# Check if ArgoCD is installed
if ! kubectl get namespace argocd &>/dev/null; then
    echo -e "${RED}ArgoCD not installed. Run ./scripts/bootstrap-platform.sh first${NC}"
    exit 1
fi

# Step 1: Generate manifests if they don't exist
MANIFEST_DIR="$PROJECT_ROOT/applications/demo-app-1/manifests/demo"
if [ ! -d "$MANIFEST_DIR" ]; then
    echo -e "${YELLOW}Step 1/4: Generating manifests...${NC}"
    "$SCRIPT_DIR/generate-manifests.sh" applications/demo-app-1 demo
else
    echo -e "${GREEN}Step 1/4: Manifests already exist${NC}"
fi
echo ""

# Step 2: Ensure demo namespace exists
echo -e "${YELLOW}Step 2/4: Creating demo namespace...${NC}"
kubectl create namespace demo --dry-run=client -o yaml | kubectl apply -f -
echo ""

# Step 3: Apply analysis templates
echo -e "${YELLOW}Step 3/4: Applying analysis templates...${NC}"
kubectl apply -f "$PROJECT_ROOT/platform-config/templates/analysis-templates/" -n argo-rollouts
echo ""

# Step 4: Deploy via direct apply (for local development without Git sync)
echo -e "${YELLOW}Step 4/4: Deploying application manifests...${NC}"
kubectl apply -f "$MANIFEST_DIR/"
echo ""

# Wait for rollout
echo -e "${YELLOW}Waiting for rollout to be ready...${NC}"
kubectl wait --for=condition=available --timeout=120s -n demo rollout/demo-app-1 2>/dev/null || \
    kubectl rollouts status rollout/demo-app-1 -n demo --timeout=120s 2>/dev/null || \
    echo "Rollout still progressing (this is normal for first deploy)"

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}Demo application deployed!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${YELLOW}Application Status:${NC}"
kubectl get rollout -n demo 2>/dev/null || kubectl get deployment -n demo
echo ""
kubectl get pods -n demo
echo ""
echo -e "${YELLOW}Access:${NC}"
echo "  App URL: http://demo-app-1.local"
echo "  (Ensure 127.0.0.1 demo-app-1.local is in /etc/hosts)"
echo ""
echo -e "${YELLOW}Useful commands:${NC}"
echo "  Watch rollout:    kubectl argo rollouts get rollout demo-app-1 -n demo --watch"
echo "  View logs:        kubectl logs -f -n demo -l app=demo-app-1"
echo "  Test endpoint:    curl http://demo-app-1.local"
echo ""
