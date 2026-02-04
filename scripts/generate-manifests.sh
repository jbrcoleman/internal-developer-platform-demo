#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

APP_DIR=$1
NAMESPACE=${2:-default}

if [ -z "$APP_DIR" ]; then
    echo -e "${RED}Usage: $0 <app-directory> [namespace]${NC}"
    echo "Example: $0 applications/demo-app-1 dev"
    exit 1
fi

CONFIG_FILE="$APP_DIR/app-config.yaml"

if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}Config file not found: $CONFIG_FILE${NC}"
    exit 1
fi

echo -e "${GREEN}Generating manifests for $APP_DIR in namespace $NAMESPACE${NC}"

# Create manifests directory
MANIFEST_DIR="$APP_DIR/manifests/$NAMESPACE"
mkdir -p "$MANIFEST_DIR"

# Extract values from config (requires yq)
if ! command -v yq &> /dev/null; then
    echo -e "${RED}yq is required but not installed${NC}"
    echo "Install with: brew install yq (macOS) or download from https://github.com/mikefarah/yq"
    exit 1
fi

APP_NAME=$(yq eval '.metadata.name' "$CONFIG_FILE")
IMAGE=$(yq eval '.spec.runtime.image' "$CONFIG_FILE")
PORT=$(yq eval '.spec.runtime.port' "$CONFIG_FILE")
CPU=$(yq eval '.spec.runtime.resources.cpu' "$CONFIG_FILE")
MEMORY=$(yq eval '.spec.runtime.resources.memory' "$CONFIG_FILE")
REPLICAS=$(yq eval '.spec.deployment.replicas' "$CONFIG_FILE")
STRATEGY=$(yq eval '.spec.deployment.strategy' "$CONFIG_FILE")
DOMAIN=$(yq eval '.spec.networking.domain' "$CONFIG_FILE")
EXPOSE=$(yq eval '.spec.networking.expose' "$CONFIG_FILE")

echo "  App: $APP_NAME"
echo "  Image: $IMAGE"
echo "  Strategy: $STRATEGY"

# Generate namespace
cat > "$MANIFEST_DIR/namespace.yaml" <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: $NAMESPACE
EOF

# Generate Rollout or Deployment based on strategy
if [ "$STRATEGY" = "canary" ]; then
    echo -e "${YELLOW}  Generating Canary Rollout...${NC}"

    ANALYSIS_ENABLED=$(yq eval '.spec.deployment.canary.analysis.enabled' "$CONFIG_FILE")

    cat > "$MANIFEST_DIR/rollout.yaml" <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: $APP_NAME
  namespace: $NAMESPACE
  labels:
    app: $APP_NAME
spec:
  replicas: $REPLICAS
  revisionHistoryLimit: 2
  selector:
    matchLabels:
      app: $APP_NAME
  template:
    metadata:
      labels:
        app: $APP_NAME
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "$PORT"
        prometheus.io/path: "/metrics"
    spec:
      containers:
      - name: $APP_NAME
        image: $IMAGE
        ports:
        - name: http
          containerPort: $PORT
          protocol: TCP
        env:
$(yq eval '.spec.runtime.env[] | "        - name: " + .name + "\n          value: \"" + .value + "\""' "$CONFIG_FILE")
        resources:
          requests:
            cpu: $CPU
            memory: $MEMORY
          limits:
            cpu: $CPU
            memory: $MEMORY
        livenessProbe:
          httpGet:
            path: /health
            port: http
          initialDelaySeconds: 10
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: http
          initialDelaySeconds: 5
          periodSeconds: 5
  strategy:
    canary:
      canaryService: $APP_NAME-canary
      stableService: $APP_NAME-stable
      trafficRouting:
        nginx:
          stableIngress: $APP_NAME
      steps:
EOF

    # Add canary steps
    yq eval '.spec.deployment.canary.steps[] | "      - setWeight: " + (.weight | tostring) + "\n      - pause: {duration: " + .pause + "}"' "$CONFIG_FILE" >> "$MANIFEST_DIR/rollout.yaml"

    # Add analysis if enabled
    if [ "$ANALYSIS_ENABLED" = "true" ]; then
        ERROR_THRESHOLD=$(yq eval '.spec.deployment.canary.analysis.errorRateThreshold' "$CONFIG_FILE")
        LATENCY_THRESHOLD=$(yq eval '.spec.deployment.canary.analysis.latencyP95Threshold' "$CONFIG_FILE")

        cat >> "$MANIFEST_DIR/rollout.yaml" <<EOF
      analysis:
        templates:
        - templateName: error-rate
          clusterScope: true
        - templateName: latency
          clusterScope: true
        args:
        - name: service-name
          value: $APP_NAME
        - name: namespace
          value: $NAMESPACE
EOF
    fi
else
    echo -e "${YELLOW}  Generating standard Deployment...${NC}"

    cat > "$MANIFEST_DIR/deployment.yaml" <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $APP_NAME
  namespace: $NAMESPACE
  labels:
    app: $APP_NAME
spec:
  replicas: $REPLICAS
  selector:
    matchLabels:
      app: $APP_NAME
  template:
    metadata:
      labels:
        app: $APP_NAME
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "$PORT"
        prometheus.io/path: "/metrics"
    spec:
      containers:
      - name: $APP_NAME
        image: $IMAGE
        ports:
        - name: http
          containerPort: $PORT
        env:
$(yq eval '.spec.runtime.env[] | "        - name: " + .name + "\n          value: \"" + .value + "\""' "$CONFIG_FILE")
        resources:
          requests:
            cpu: $CPU
            memory: $MEMORY
        livenessProbe:
          httpGet:
            path: /health
            port: http
        readinessProbe:
          httpGet:
            path: /health
            port: http
EOF
fi

# Generate Services
if [ "$STRATEGY" = "canary" ]; then
    # Canary needs two services
    cat > "$MANIFEST_DIR/services.yaml" <<EOF
apiVersion: v1
kind: Service
metadata:
  name: $APP_NAME-stable
  namespace: $NAMESPACE
  labels:
    app: $APP_NAME
spec:
  type: ClusterIP
  ports:
  - port: 80
    targetPort: http
    protocol: TCP
    name: http
  selector:
    app: $APP_NAME
---
apiVersion: v1
kind: Service
metadata:
  name: $APP_NAME-canary
  namespace: $NAMESPACE
  labels:
    app: $APP_NAME
spec:
  type: ClusterIP
  ports:
  - port: 80
    targetPort: http
    protocol: TCP
    name: http
  selector:
    app: $APP_NAME
EOF
else
    cat > "$MANIFEST_DIR/services.yaml" <<EOF
apiVersion: v1
kind: Service
metadata:
  name: $APP_NAME
  namespace: $NAMESPACE
  labels:
    app: $APP_NAME
spec:
  type: ClusterIP
  ports:
  - port: 80
    targetPort: http
    protocol: TCP
    name: http
  selector:
    app: $APP_NAME
EOF
fi

# Generate Ingress if expose is true
if [ "$EXPOSE" = "true" ]; then
    cat > "$MANIFEST_DIR/ingress.yaml" <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: $APP_NAME
  namespace: $NAMESPACE
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
spec:
  ingressClassName: nginx
  rules:
  - host: $DOMAIN
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: $APP_NAME-stable
            port:
              number: 80
EOF
fi

# Generate ServiceMonitor for Prometheus
cat > "$MANIFEST_DIR/servicemonitor.yaml" <<EOF
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: $APP_NAME
  namespace: $NAMESPACE
  labels:
    app: $APP_NAME
spec:
  selector:
    matchLabels:
      app: $APP_NAME
  endpoints:
  - port: http
    path: /metrics
    interval: 30s
EOF

echo -e "${GREEN}Manifests generated in $MANIFEST_DIR${NC}"
echo ""
echo "Files created:"
ls -1 "$MANIFEST_DIR"
