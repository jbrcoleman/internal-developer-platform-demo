#!/bin/bash
set -e

echo "📥 Installing Prometheus stack..."

# Add Prometheus community Helm repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Create namespace
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

# Install Prometheus stack
echo "⏳ Installing kube-prometheus-stack (this may take a few minutes)..."
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
  --set prometheus.prometheusSpec.podMonitorSelectorNilUsesHelmValues=false \
  --set grafana.adminPassword=admin \
  --wait \
  --timeout 10m

echo ""
echo "✅ Prometheus stack installed successfully!"
echo ""
kubectl get pods -n monitoring
echo ""
echo "==========================================="
echo "Grafana Credentials"
echo "==========================================="
echo "URL: http://grafana.local"
echo "Username: admin"
echo "Password: admin"
echo "==========================================="
