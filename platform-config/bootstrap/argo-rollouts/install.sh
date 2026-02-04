#!/bin/bash
set -e

echo "📥 Installing Argo Rollouts..."

# Create namespace
kubectl create namespace argo-rollouts --dry-run=client -o yaml | kubectl apply -f -

# Install Argo Rollouts
kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml

# Wait for rollouts controller to be ready
echo "⏳ Waiting for Argo Rollouts to be ready..."
kubectl wait --for=condition=available --timeout=300s \
  deployment/argo-rollouts -n argo-rollouts

echo ""
echo "✅ Argo Rollouts installed successfully!"
echo ""
kubectl get pods -n argo-rollouts
