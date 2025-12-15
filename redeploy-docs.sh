#!/bin/bash
#
# Quick rebuild and redeploy documentation to local Kubernetes cluster
#

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
  echo -e "${GREEN}✓${NC} $1"
}

print_error() {
  echo -e "${RED}✗${NC} $1"
}

print_info() {
  echo -e "${YELLOW}ℹ${NC} $1"
}

print_section() {
  echo ""
  echo -e "${BLUE}▶ $1${NC}"
  echo "----------------------------------------"
}

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Rebuilding and Redeploying Docs${NC}"
echo -e "${BLUE}========================================${NC}"

# Detect Kubernetes environment
print_section "Detecting Kubernetes Environment"

K8S_TYPE=""
if kubectl config current-context 2>/dev/null | grep -q "minikube"; then
  K8S_TYPE="minikube"
  print_status "Detected minikube"
elif kubectl config current-context 2>/dev/null | grep -q "rancher-desktop"; then
  K8S_TYPE="rancher-desktop"
  print_status "Detected Rancher Desktop"
else
  K8S_TYPE="other"
  print_status "Detected other Kubernetes environment"
fi

# Build the Docker image
print_section "Building Docker Image"

cd markdown
IMAGE_NAME="partner-demo-docs"
IMAGE_TAG="local-$(date +%s)"

print_info "Building image: ${IMAGE_NAME}:${IMAGE_TAG}"

if docker build -t ${IMAGE_NAME}:${IMAGE_TAG} -t ${IMAGE_NAME}:latest .; then
  print_status "Docker image built successfully"
else
  print_error "Docker build failed"
  exit 1
fi

cd ..

# Load image into cluster (minikube only)
if [ "$K8S_TYPE" = "minikube" ]; then
  print_section "Loading Image into Minikube"

  if minikube image load ${IMAGE_NAME}:latest; then
    print_status "Image loaded into minikube"
  else
    print_error "Failed to load image into minikube"
    exit 1
  fi
else
  print_info "Using local Docker daemon (Rancher Desktop or other)"
fi

# Update the deployment to use local image
print_section "Updating Deployment"

# Create a temporary deployment file with the local image
cat > /tmp/docs-deployment-local.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: docs-deployment
  labels:
    app: docs
spec:
  replicas: 1
  selector:
    matchLabels:
      app: docs
  template:
    metadata:
      labels:
        app: docs
    spec:
      containers:
      - name: docs
        image: ${IMAGE_NAME}:latest
        imagePullPolicy: Never
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "128Mi"
            cpu: "100m"
---
apiVersion: v1
kind: Service
metadata:
  name: docs-service
spec:
  type: NodePort
  selector:
    app: docs
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
      nodePort: 30001
EOF

print_info "Applying updated deployment..."

if kubectl apply -f /tmp/docs-deployment-local.yaml; then
  print_status "Deployment updated"
else
  print_error "Deployment update failed"
  exit 1
fi

# Restart the deployment to pick up the new image
print_info "Restarting deployment..."

if kubectl rollout restart deployment/docs-deployment; then
  print_status "Deployment restarted"
else
  print_error "Deployment restart failed"
  exit 1
fi

# Wait for rollout to complete
print_info "Waiting for rollout to complete..."

if kubectl rollout status deployment/docs-deployment --timeout=60s; then
  print_status "Rollout completed successfully"
else
  print_error "Rollout did not complete in time"
  exit 1
fi

# Cleanup
rm /tmp/docs-deployment-local.yaml

print_section "Done!"
echo ""
echo -e "${GREEN}Documentation has been rebuilt and redeployed!${NC}"
echo ""
echo -e "Access the docs at: ${BLUE}http://localhost:30001${NC}"
echo ""

if [ "$K8S_TYPE" = "minikube" ]; then
  echo -e "${YELLOW}Note: Make sure 'minikube tunnel' is running to access the service${NC}"
fi
