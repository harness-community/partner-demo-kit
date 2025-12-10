#!/bin/bash
#
# Harness Partner Demo Kit - Startup Script
#
# This script sets up and starts all local infrastructure needed for the demo:
# - Kubernetes cluster (minikube or Rancher Desktop)
# - Prometheus monitoring
# - Backend Docker image build and push
#
# Usage: ./start-demo.sh [--skip-docker-build]
#

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SKIP_DOCKER_BUILD=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --skip-docker-build)
      SKIP_DOCKER_BUILD=true
      shift
      ;;
    *)
      echo -e "${RED}Unknown option: $1${NC}"
      echo "Usage: ./start-demo.sh [--skip-docker-build]"
      exit 1
      ;;
  esac
done

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Harness Partner Demo Kit - Startup${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Function to print status messages
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

# Check prerequisites
print_section "Checking Prerequisites"

# Check Docker
if ! command -v docker &> /dev/null; then
  print_error "Docker is not installed. Please install Docker Desktop or Docker Engine."
  exit 1
fi
print_status "Docker found: $(docker --version | head -n1)"

# Check kubectl
if ! command -v kubectl &> /dev/null; then
  print_error "kubectl is not installed. Please install kubectl."
  exit 1
fi
print_status "kubectl found: $(kubectl version --client --short 2>/dev/null || kubectl version --client 2>&1 | head -n1)"

# Check if Docker is running
if ! docker info &> /dev/null; then
  print_error "Docker is not running. Please start Docker Desktop."
  exit 1
fi
print_status "Docker daemon is running"

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
  # Try to connect to see if any cluster is available
  if kubectl cluster-info &> /dev/null; then
    K8S_TYPE="other"
    print_status "Detected Kubernetes cluster: $(kubectl config current-context)"
  else
    print_error "No Kubernetes cluster detected."
    echo ""
    echo "Please ensure one of the following is running:"
    echo "  - Rancher Desktop with Kubernetes enabled"
    echo "  - minikube (run 'minikube start')"
    exit 1
  fi
fi

# Start minikube if needed
if [ "$K8S_TYPE" = "minikube" ]; then
  print_section "Starting minikube"

  if minikube status | grep -q "host: Running"; then
    print_status "minikube is already running"
  else
    print_info "Starting minikube (this may take a few minutes)..."
    minikube start
    print_status "minikube started successfully"
  fi

  # Enable metrics-server
  print_info "Ensuring metrics-server addon is enabled..."
  minikube addons enable metrics-server &> /dev/null
  print_status "metrics-server addon enabled"
fi

# Verify cluster connectivity
print_section "Verifying Cluster Connectivity"
if kubectl cluster-info &> /dev/null; then
  print_status "Successfully connected to Kubernetes cluster"
  print_info "Cluster: $(kubectl config current-context)"
else
  print_error "Cannot connect to Kubernetes cluster"
  exit 1
fi

# Deploy Prometheus
print_section "Deploying Prometheus"

# Check if monitoring namespace exists
if kubectl get namespace monitoring &> /dev/null; then
  print_info "Monitoring namespace already exists"
else
  print_info "Creating monitoring namespace..."
  kubectl create namespace monitoring
  print_status "Monitoring namespace created"
fi

# Check if Prometheus is already deployed
if kubectl get pods -n monitoring | grep -q prometheus-k8s-0; then
  if kubectl get pods -n monitoring | grep prometheus-k8s-0 | grep -q "Running"; then
    print_status "Prometheus is already running"
  else
    print_info "Prometheus pod exists but not running, redeploying..."
    kubectl -n monitoring delete -f kit/prometheus.yml --ignore-not-found=true &> /dev/null
    sleep 5
    kubectl -n monitoring apply -f kit/prometheus.yml
    print_status "Prometheus redeployed"
  fi
else
  print_info "Deploying Prometheus..."
  kubectl -n monitoring apply -f kit/prometheus.yml
  print_status "Prometheus deployed"
fi

# Wait for Prometheus to be ready
print_info "Waiting for Prometheus to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=prometheus -n monitoring --timeout=120s &> /dev/null || true
if kubectl get pods -n monitoring | grep prometheus-k8s-0 | grep -q "Running"; then
  print_status "Prometheus is running"
else
  print_error "Prometheus failed to start. Check with: kubectl get pods -n monitoring"
fi

# Build and push Docker images (optional)
if [ "$SKIP_DOCKER_BUILD" = false ]; then
  print_section "Building Backend Docker Image"

  print_info "Checking Docker Hub authentication..."
  # Try to get Docker Hub username from config
  DOCKER_USERNAME=""
  if [ -f "kit/se-parms.tfvars" ]; then
    DOCKER_USERNAME=$(grep docker_username kit/se-parms.tfvars | cut -d'"' -f2 2>/dev/null || echo "")
  fi

  if [ -z "$DOCKER_USERNAME" ]; then
    print_info "Docker Hub username not found in kit/se-parms.tfvars"
    read -p "Enter your Docker Hub username: " DOCKER_USERNAME
  else
    print_info "Found Docker Hub username: $DOCKER_USERNAME"
  fi

  # Check if logged in to Docker Hub
  if docker info 2>/dev/null | grep -q "Username"; then
    print_status "Already logged in to Docker Hub"
  else
    print_info "Please log in to Docker Hub"
    docker login -u "$DOCKER_USERNAME"
  fi

  # Build backend image
  print_info "Building backend Docker image (this may take a few minutes)..."
  cd backend
  docker build -t "$DOCKER_USERNAME/harness-demo:backend-latest" . --quiet
  print_status "Backend image built: $DOCKER_USERNAME/harness-demo:backend-latest"

  # Push backend image
  print_info "Pushing backend image to Docker Hub..."
  docker push "$DOCKER_USERNAME/harness-demo:backend-latest" --quiet
  print_status "Backend image pushed to Docker Hub"
  cd ..
else
  print_info "Skipping Docker image build (--skip-docker-build flag used)"
fi

# Display status
print_section "Infrastructure Status"

echo ""
echo "Kubernetes Cluster:"
kubectl get nodes

echo ""
echo "Prometheus Status:"
kubectl get pods -n monitoring

if [ "$K8S_TYPE" = "minikube" ]; then
  echo ""
  print_info "NOTE: For minikube, you need to run 'minikube tunnel' in a separate terminal"
  print_info "to access services at localhost:8080"
fi

# Display next steps
print_section "Next Steps"
echo ""
echo "Your local infrastructure is ready! 🚀"
echo ""
echo "Next steps:"
echo "  1. Configure Terraform variables in kit/se-parms.tfvars"
echo "  2. Run Terraform to create Harness resources:"
echo "     cd kit"
echo "     export DEMO_BASE_PAT=\"your-harness-pat\""
echo "     terraform init"
echo "     terraform plan -var=\"pat=\$DEMO_BASE_PAT\" -var-file=\"se-parms.tfvars\" -out=plan.tfplan"
echo "     terraform apply -auto-approve plan.tfplan"
echo "  3. Follow the lab guides in the markdown/ directory"
echo ""

if [ "$K8S_TYPE" = "minikube" ]; then
  echo "⚠️  IMPORTANT for minikube users:"
  echo "     Run this in a separate terminal and keep it running:"
  echo "     minikube tunnel"
  echo ""
fi

print_status "Startup complete!"
echo ""
