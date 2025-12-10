#!/bin/bash
#
# Harness Partner Demo Kit - Shutdown Script
#
# This script cleans up and stops all local infrastructure created for the demo:
# - Deletes deployed applications (frontend, backend)
# - Optionally removes Prometheus
# - Optionally stops Kubernetes cluster
#
# Usage: ./stop-demo.sh [OPTIONS]
#   OPTIONS:
#     --delete-prometheus    Also delete Prometheus monitoring
#     --stop-cluster         Stop the Kubernetes cluster (minikube only)
#     --full-cleanup         Delete everything including Prometheus and stop cluster
#

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DELETE_PROMETHEUS=false
STOP_CLUSTER=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --delete-prometheus)
      DELETE_PROMETHEUS=true
      shift
      ;;
    --stop-cluster)
      STOP_CLUSTER=true
      shift
      ;;
    --full-cleanup)
      DELETE_PROMETHEUS=true
      STOP_CLUSTER=true
      shift
      ;;
    *)
      echo -e "${RED}Unknown option: $1${NC}"
      echo "Usage: ./stop-demo.sh [--delete-prometheus] [--stop-cluster] [--full-cleanup]"
      exit 1
      ;;
  esac
done

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Harness Partner Demo Kit - Shutdown${NC}"
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

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
  print_error "kubectl is not installed. Cannot proceed with cleanup."
  exit 1
fi

# Check if cluster is accessible
if ! kubectl cluster-info &> /dev/null; then
  print_error "Cannot connect to Kubernetes cluster"
  print_info "Cluster may already be stopped or not configured"
  exit 1
fi

print_info "Connected to cluster: $(kubectl config current-context)"

# Detect Kubernetes environment
K8S_TYPE=""
if kubectl config current-context 2>/dev/null | grep -q "minikube"; then
  K8S_TYPE="minikube"
elif kubectl config current-context 2>/dev/null | grep -q "rancher-desktop"; then
  K8S_TYPE="rancher-desktop"
else
  K8S_TYPE="other"
fi

# Delete deployed applications
print_section "Cleaning Up Deployed Applications"

# Delete frontend deployment and service
if kubectl get deployment frontend-deployment &> /dev/null; then
  print_info "Deleting frontend deployment..."
  kubectl delete deployment frontend-deployment --ignore-not-found=true
  print_status "Frontend deployment deleted"
else
  print_info "Frontend deployment not found (already deleted)"
fi

if kubectl get service web-frontend-svc &> /dev/null; then
  print_info "Deleting frontend service..."
  kubectl delete service web-frontend-svc --ignore-not-found=true
  print_status "Frontend service deleted"
else
  print_info "Frontend service not found (already deleted)"
fi

# Delete backend deployment and service
if kubectl get deployment backend-deployment &> /dev/null; then
  print_info "Deleting backend deployment..."
  kubectl delete deployment backend-deployment --ignore-not-found=true
  print_status "Backend deployment deleted"
else
  print_info "Backend deployment not found (already deleted)"
fi

if kubectl get service web-backend-svc &> /dev/null; then
  print_info "Deleting backend service..."
  kubectl delete service web-backend-svc --ignore-not-found=true
  print_status "Backend service deleted"
else
  print_info "Backend service not found (already deleted)"
fi

# Delete any remaining pods
print_info "Checking for remaining application pods..."
REMAINING_PODS=$(kubectl get pods --no-headers 2>/dev/null | grep -E "frontend|backend" | wc -l)
if [ "$REMAINING_PODS" -gt 0 ]; then
  print_info "Waiting for pods to terminate..."
  sleep 5
  print_status "Application pods cleaned up"
else
  print_status "No application pods found"
fi

# Delete Prometheus (optional)
if [ "$DELETE_PROMETHEUS" = true ]; then
  print_section "Deleting Prometheus"

  if kubectl get namespace monitoring &> /dev/null; then
    print_info "Deleting Prometheus deployment..."
    kubectl -n monitoring delete -f kit/prometheus.yml --ignore-not-found=true &> /dev/null || true
    print_status "Prometheus deleted"

    print_info "Deleting monitoring namespace..."
    kubectl delete namespace monitoring --ignore-not-found=true &> /dev/null || true
    print_status "Monitoring namespace deleted"
  else
    print_info "Monitoring namespace not found (already deleted)"
  fi
else
  print_info "Keeping Prometheus running (use --delete-prometheus to remove)"
fi

# Display current status
print_section "Current Cluster Status"

echo ""
echo "Namespaces:"
kubectl get namespaces | grep -E "NAME|default|monitoring|harness" || echo "  Default namespaces only"

echo ""
echo "Deployments in default namespace:"
DEPLOYMENTS=$(kubectl get deployments --no-headers 2>/dev/null | wc -l)
if [ "$DEPLOYMENTS" -eq 0 ]; then
  echo "  No deployments found"
else
  kubectl get deployments
fi

echo ""
echo "Services in default namespace:"
SERVICES=$(kubectl get services --no-headers 2>/dev/null | grep -v kubernetes | wc -l)
if [ "$SERVICES" -eq 0 ]; then
  echo "  No services found (except kubernetes default)"
else
  kubectl get services | grep -v kubernetes
fi

# Stop cluster (optional, minikube only)
if [ "$STOP_CLUSTER" = true ]; then
  if [ "$K8S_TYPE" = "minikube" ]; then
    print_section "Stopping minikube"

    print_info "Stopping minikube cluster..."
    minikube stop
    print_status "minikube stopped"
  elif [ "$K8S_TYPE" = "rancher-desktop" ]; then
    print_info "Cannot automatically stop Rancher Desktop"
    print_info "Please stop it manually through the Rancher Desktop UI"
  else
    print_info "Cluster type '$K8S_TYPE' - not stopping automatically"
  fi
else
  if [ "$K8S_TYPE" = "minikube" ]; then
    print_info "Keeping minikube running (use --stop-cluster to stop)"
  fi
fi

# Display completion message
print_section "Cleanup Summary"
echo ""
echo "Cleanup complete! 🧹"
echo ""
echo "What was removed:"
echo "  ✓ Frontend deployment and service"
echo "  ✓ Backend deployment and service"

if [ "$DELETE_PROMETHEUS" = true ]; then
  echo "  ✓ Prometheus monitoring"
else
  echo "  ⊘ Prometheus monitoring (still running)"
fi

if [ "$STOP_CLUSTER" = true ] && [ "$K8S_TYPE" = "minikube" ]; then
  echo "  ✓ Kubernetes cluster (minikube stopped)"
else
  echo "  ⊘ Kubernetes cluster (still running)"
fi

echo ""
echo "What remains:"
if [ "$DELETE_PROMETHEUS" = false ]; then
  echo "  • Prometheus monitoring (in 'monitoring' namespace)"
fi
if [ "$STOP_CLUSTER" = false ]; then
  echo "  • Kubernetes cluster ($(kubectl config current-context))"
fi
echo "  • Docker images (use 'docker images' to view)"
echo "  • Harness resources (use Terraform or Harness UI to manage)"
echo ""

if [ "$DELETE_PROMETHEUS" = false ] || [ "$STOP_CLUSTER" = false ]; then
  echo "For complete cleanup, run:"
  echo "  ./stop-demo.sh --full-cleanup"
  echo ""
fi

print_status "Shutdown complete!"
echo ""
