#!/bin/bash
set -e

echo "🔧 Installing required tools..."

# Check OS
OS="$(uname -s)"

install_kind() {
    echo "Installing kind..."
    if [ "$OS" = "Darwin" ]; then
        brew install kind
    else
        curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
        chmod +x ./kind
        sudo mv ./kind /usr/local/bin/kind
    fi
}

install_kubectl() {
    echo "Installing kubectl..."
    if [ "$OS" = "Darwin" ]; then
        brew install kubectl
    else
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        chmod +x kubectl
        sudo mv kubectl /usr/local/bin/
    fi
}

install_helm() {
    echo "Installing helm..."
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
}

install_argocd_cli() {
    echo "Installing ArgoCD CLI..."
    if [ "$OS" = "Darwin" ]; then
        brew install argocd
    else
        curl -sSL -o argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
        chmod +x argocd
        sudo mv argocd /usr/local/bin/
    fi
}

install_argo_rollouts_plugin() {
    echo "Installing Argo Rollouts kubectl plugin..."
    if [ "$OS" = "Darwin" ]; then
        brew install argoproj/tap/kubectl-argo-rollouts
    else
        curl -LO https://github.com/argoproj/argo-rollouts/releases/latest/download/kubectl-argo-rollouts-linux-amd64
        chmod +x kubectl-argo-rollouts-linux-amd64
        sudo mv kubectl-argo-rollouts-linux-amd64 /usr/local/bin/kubectl-argo-rollouts
    fi
}

install_yq() {
    echo "Installing yq..."
    if [ "$OS" = "Darwin" ]; then
        brew install yq
    else
        curl -LO https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
        chmod +x yq_linux_amd64
        sudo mv yq_linux_amd64 /usr/local/bin/yq
    fi
}

# Check and install each tool
command -v kind >/dev/null 2>&1 || install_kind
command -v kubectl >/dev/null 2>&1 || install_kubectl
command -v helm >/dev/null 2>&1 || install_helm
command -v argocd >/dev/null 2>&1 || install_argocd_cli
command -v kubectl-argo-rollouts >/dev/null 2>&1 || install_argo_rollouts_plugin
command -v yq >/dev/null 2>&1 || install_yq

echo ""
echo "✅ All tools installed successfully!"
echo ""
echo "Installed versions:"
kind --version 2>/dev/null || echo "kind: not installed"
kubectl version --client --short 2>/dev/null || kubectl version --client 2>/dev/null | head -1
helm version --short 2>/dev/null || echo "helm: not installed"
argocd version --client 2>/dev/null | head -1 || echo "argocd: not installed"
kubectl argo rollouts version 2>/dev/null || echo "kubectl-argo-rollouts: not installed"
yq --version 2>/dev/null || echo "yq: not installed"
