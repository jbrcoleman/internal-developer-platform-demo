#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "🚀 Creating kind cluster..."

# Delete existing cluster if it exists
kind delete cluster --name platform-demo 2>/dev/null || true

# Create new cluster
kind create cluster --config "$PROJECT_ROOT/platform-config/bootstrap/kind-config.yaml"

# Wait for cluster to be ready
echo "⏳ Waiting for nodes to be ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=300s

echo ""
echo "✅ Cluster created successfully!"
echo ""
kubectl get nodes
