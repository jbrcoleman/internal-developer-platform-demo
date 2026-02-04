#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

VERSION=${1:-v2}
APP_NAME=${2:-demo-app-1}
NAMESPACE=${3:-demo}

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Triggering Canary Rollout${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "  App:       ${GREEN}$APP_NAME${NC}"
echo -e "  Namespace: ${GREEN}$NAMESPACE${NC}"
echo -e "  Version:   ${GREEN}$VERSION${NC}"
echo ""

# Check if the image exists in kind
echo -e "${YELLOW}Checking if image exists in cluster...${NC}"
if ! docker exec platform-demo-control-plane crictl images | grep -q "sample-service.*$VERSION"; then
    echo -e "${YELLOW}Image sample-service:$VERSION not found in cluster, loading...${NC}"

    # Build if needed
    if ! docker images | grep -q "sample-service.*$VERSION"; then
        echo "Building sample-service:$VERSION..."
        cd demo-apps/sample-service
        docker build -t sample-service:$VERSION .
        cd ../..
    fi

    kind load docker-image sample-service:$VERSION --name platform-demo
fi
echo -e "${GREEN}Image ready${NC}"
echo ""

# Update the rollout image
echo -e "${YELLOW}Updating rollout to sample-service:$VERSION...${NC}"
kubectl argo rollouts set image $APP_NAME $APP_NAME=sample-service:$VERSION -n $NAMESPACE

echo ""
echo -e "${GREEN}Rollout triggered!${NC}"
echo ""
echo -e "${YELLOW}Watch the rollout progress:${NC}"
echo "  kubectl argo rollouts get rollout $APP_NAME -n $NAMESPACE --watch"
echo ""
echo -e "${YELLOW}Or use the dashboard:${NC}"
echo "  http://rollouts.local"
echo ""

# Optionally watch
read -p "Watch rollout progress? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    kubectl argo rollouts get rollout $APP_NAME -n $NAMESPACE --watch
fi
