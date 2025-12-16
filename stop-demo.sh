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
#     --delete-prometheus       Also delete Prometheus monitoring
#     --stop-cluster            Stop the Kubernetes cluster (minikube only)
#     --delete-harness-project  Delete Harness "Base Demo" project via API
#     --delete-docker-repo      Delete Docker Hub harness-demo repository via API
#     --delete-config-files     Delete .demo-config, se-parms.tfvars, and IaC state files
#     --full-cleanup            Delete everything (all of the above)
#

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DELETE_PROMETHEUS=false
STOP_CLUSTER=false
DELETE_HARNESS_PROJECT=false
DELETE_DOCKER_REPO=false
DELETE_CONFIG_FILES=false

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
    --delete-harness-project)
      DELETE_HARNESS_PROJECT=true
      shift
      ;;
    --delete-docker-repo)
      DELETE_DOCKER_REPO=true
      shift
      ;;
    --delete-config-files)
      DELETE_CONFIG_FILES=true
      shift
      ;;
    --full-cleanup)
      DELETE_PROMETHEUS=true
      STOP_CLUSTER=true
      DELETE_HARNESS_PROJECT=true
      DELETE_DOCKER_REPO=true
      DELETE_CONFIG_FILES=true
      shift
      ;;
    *)
      echo -e "${RED}Unknown option: $1${NC}"
      echo "Usage: ./stop-demo.sh [OPTIONS]"
      echo "  --delete-prometheus       Delete Prometheus monitoring"
      echo "  --stop-cluster            Stop Kubernetes cluster (minikube only)"
      echo "  --delete-harness-project  Delete Harness 'Base Demo' project"
      echo "  --delete-docker-repo      Delete Docker Hub repository"
      echo "  --delete-config-files     Delete config and state files"
      echo "  --full-cleanup            All of the above"
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

# Load credentials from config file if it exists
CONFIG_FILE=".demo-config"
HARNESS_ACCOUNT_ID=""
HARNESS_PAT=""
DOCKER_USERNAME=""
DOCKER_PAT=""

if [ -f "$CONFIG_FILE" ]; then
  print_info "Loading credentials from $CONFIG_FILE..."
  HARNESS_ACCOUNT_ID=$(grep "HARNESS_ACCOUNT_ID=" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2)
  HARNESS_PAT=$(grep "HARNESS_PAT=" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2)
  DOCKER_USERNAME=$(grep "DOCKER_USERNAME=" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2)
  DOCKER_PAT=$(grep "DOCKER_PAT=" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2)

  # Show what was loaded (for debugging)
  if [ -n "$HARNESS_ACCOUNT_ID" ]; then
    print_status "Loaded Harness Account ID from config"
  fi
  if [ -n "$HARNESS_PAT" ]; then
    print_status "Loaded Harness PAT from config"
  fi
  if [ -n "$DOCKER_USERNAME" ]; then
    print_status "Loaded Docker username from config"
  fi
  if [ -n "$DOCKER_PAT" ]; then
    print_status "Loaded Docker password from config"
  fi
else
  print_info "Config file $CONFIG_FILE not found"
fi

# Check environment variable for Harness PAT (overrides cached value)
if [ -n "$DEMO_BASE_PAT" ]; then
  HARNESS_PAT="$DEMO_BASE_PAT"
  print_status "Using Harness PAT from DEMO_BASE_PAT environment variable"
fi

# Try to load from se-parms.tfvars as fallback
if [ -f "kit/se-parms.tfvars" ]; then
  if [ -z "$HARNESS_ACCOUNT_ID" ]; then
    HARNESS_ACCOUNT_ID=$(grep account_id kit/se-parms.tfvars 2>/dev/null | cut -d'"' -f2)
    if [ -n "$HARNESS_ACCOUNT_ID" ]; then
      print_status "Loaded Harness Account ID from kit/se-parms.tfvars"
    fi
  fi
  if [ -z "$DOCKER_USERNAME" ]; then
    DOCKER_USERNAME=$(grep docker_username kit/se-parms.tfvars 2>/dev/null | cut -d'"' -f2)
    if [ -n "$DOCKER_USERNAME" ]; then
      print_status "Loaded Docker username from kit/se-parms.tfvars"
    fi
  fi
  if [ -z "$DOCKER_PAT" ]; then
    DOCKER_PAT=$(grep DOCKER_PAT kit/se-parms.tfvars 2>/dev/null | cut -d'"' -f2)
    if [ -n "$DOCKER_PAT" ]; then
      print_status "Loaded Docker password from kit/se-parms.tfvars"
    fi
  fi
fi

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
  print_error "kubectl is not installed. Cannot proceed with Kubernetes cleanup."

  # If only doing Harness/Docker cleanup, we can continue
  if [ "$DELETE_HARNESS_PROJECT" = true ] || [ "$DELETE_DOCKER_REPO" = true ] || [ "$DELETE_CONFIG_FILES" = true ]; then
    print_info "Continuing with Harness/Docker/config cleanup only..."
  else
    exit 1
  fi
fi

# Check if cluster is accessible (skip if only doing non-k8s cleanup)
if command -v kubectl &> /dev/null; then
  if ! kubectl cluster-info &> /dev/null; then
    print_error "Cannot connect to Kubernetes cluster"
    print_info "Cluster may already be stopped or not configured"

    # If only doing Harness/Docker cleanup, we can continue
    if [ "$DELETE_HARNESS_PROJECT" = true ] || [ "$DELETE_DOCKER_REPO" = true ] || [ "$DELETE_CONFIG_FILES" = true ]; then
      print_info "Continuing with Harness/Docker/config cleanup only..."
      K8S_AVAILABLE=false
    else
      exit 1
    fi
  else
    print_info "Connected to cluster: $(kubectl config current-context)"
    K8S_AVAILABLE=true
  fi
else
  K8S_AVAILABLE=false
fi

# Detect Kubernetes environment
K8S_TYPE=""
if [ "$K8S_AVAILABLE" = true ]; then
  if kubectl config current-context 2>/dev/null | grep -q "minikube"; then
    K8S_TYPE="minikube"
  elif kubectl config current-context 2>/dev/null | grep -q "rancher-desktop"; then
    K8S_TYPE="rancher-desktop"
  else
    K8S_TYPE="other"
  fi
fi

# Delete deployed applications
if [ "$K8S_AVAILABLE" = true ]; then
  print_section "Cleaning Up Deployed Applications"
else
  print_info "Skipping Kubernetes cleanup (cluster not available)"
fi

if [ "$K8S_AVAILABLE" = true ]; then

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

# Delete documentation deployment and service
if kubectl get deployment docs-deployment &> /dev/null; then
  print_info "Deleting documentation deployment..."
  kubectl delete deployment docs-deployment --ignore-not-found=true
  print_status "Documentation deployment deleted"
else
  print_info "Documentation deployment not found (already deleted)"
fi

if kubectl get service docs-service &> /dev/null; then
  print_info "Deleting documentation service..."
  kubectl delete service docs-service --ignore-not-found=true
  print_status "Documentation service deleted"
else
  print_info "Documentation service not found (already deleted)"
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

fi  # End of K8S_AVAILABLE check

# Delete Harness Resources (optional)
if [ "$DELETE_HARNESS_PROJECT" = true ]; then
  print_section "Deleting Harness Resources"

  # Check if IaC state file exists
  if [ ! -f "kit/terraform.tfstate" ] || [ ! -s "kit/terraform.tfstate" ]; then
    print_info "No IaC state file found - Harness resources may not exist or were already deleted"
    read -p "Do you want to try deleting via API anyway? (yes/no): " TRY_API

    if [ "$TRY_API" != "yes" ]; then
      print_info "Skipping Harness resource deletion"
    else
      print_info "API-based deletion not implemented - use Harness UI to manually delete resources"
    fi
  else
    # We have a state file, use IaC to destroy
    print_info "Found IaC state file - will use Terraform to destroy resources"

    # Prompt for confirmation
    echo ""
    echo -e "${YELLOW}WARNING: This will permanently delete all Harness resources created by IaC:${NC}"
    echo "  - 'Base Demo' project"
    echo "  - Code repositories"
    echo "  - Pipelines"
    echo "  - Services"
    echo "  - Environments"
    echo "  - Connectors"
    echo "  - All other resources in the state file"
    echo ""
    read -p "Are you sure you want to destroy these Harness resources? (yes/no): " CONFIRM_HARNESS

    if [ "$CONFIRM_HARNESS" = "yes" ]; then
      # Need Harness PAT for destroy
      if [ -z "$HARNESS_PAT" ]; then
        echo ""
        print_info "Harness PAT not found in config files"
        echo "You can use the DEMO_BASE_PAT environment variable or enter it now"
        echo ""
        read -p "Enter your Harness PAT (or press Enter to skip): " HARNESS_PAT
      fi

      if [ -z "$HARNESS_PAT" ]; then
        print_info "Skipping Harness resource deletion (PAT not provided)"
      else
        # Check for Terraform
        if ! command -v terraform &> /dev/null; then
          print_error "Terraform not found"
          print_info "Cannot destroy Harness resources without Terraform"
          print_info "Please install Terraform, or delete resources manually through Harness UI"
        else
          print_status "Using Terraform for destroy"
          print_info "Running terraform destroy (this may take 2-3 minutes)..."

          cd kit
          if terraform destroy -var="pat=$HARNESS_PAT" -var-file="se-parms.tfvars" -auto-approve; then
            print_status "Harness resources destroyed successfully"
          else
            print_error "Terraform destroy encountered errors"
            print_info "Some resources may have been deleted. Check kit/terraform.tfstate"
            print_info "You may need to manually delete remaining resources through Harness UI"
          fi
          cd ..
        fi
      fi
    else
      print_info "Skipping Harness resource deletion (user cancelled)"
    fi
  fi
fi

# Delete Docker Hub Repository (optional)
if [ "$DELETE_DOCKER_REPO" = true ]; then
  print_section "Deleting Docker Hub Repository"

  # Check if we have credentials, prompt if missing
  if [ -z "$DOCKER_USERNAME" ]; then
    echo ""
    print_info "Docker Hub username not found in config files"
    read -p "Enter your Docker Hub username (or press Enter to skip): " DOCKER_USERNAME
  fi

  if [ -z "$DOCKER_PAT" ] || [ "$DOCKER_PAT" = "logged-in-via-docker-desktop" ]; then
    echo ""
    print_info "Docker Hub password/PAT not found in config files"
    echo "To create a PAT: https://hub.docker.com/settings/security"
    echo ""
    read -sp "Enter your Docker Hub password/PAT (or press Enter to skip): " DOCKER_PAT
    echo ""
  fi

  # Check again after prompting
  if [ -z "$DOCKER_USERNAME" ] || [ -z "$DOCKER_PAT" ] || [ "$DOCKER_PAT" = "logged-in-via-docker-desktop" ]; then
    print_info "Skipping Docker Hub repository deletion (credentials not provided)"
  else
    # Prompt for confirmation
    echo ""
    echo -e "${YELLOW}WARNING: This will permanently delete the Docker Hub repository:${NC}"
    echo "  Repository: $DOCKER_USERNAME/harness-demo"
    echo "  All images and tags will be deleted"
    echo ""
    read -p "Are you sure you want to delete this Docker Hub repository? (yes/no): " CONFIRM_DOCKER

    if [ "$CONFIRM_DOCKER" = "yes" ]; then
      print_info "Deleting Docker Hub repository '$DOCKER_USERNAME/harness-demo'..."

      # First, get a JWT token from Docker Hub
      TOKEN_RESPONSE=$(curl -s -X POST \
        "https://hub.docker.com/v2/users/login" \
        -H "Content-Type: application/json" \
        -d "{\"username\":\"${DOCKER_USERNAME}\",\"password\":\"${DOCKER_PAT}\"}")

      JWT_TOKEN=$(echo "$TOKEN_RESPONSE" | grep -o '"token":"[^"]*' | cut -d'"' -f4)

      if [ -n "$JWT_TOKEN" ]; then
        # Delete the repository
        HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE \
          "https://hub.docker.com/v2/repositories/${DOCKER_USERNAME}/harness-demo/" \
          -H "Authorization: JWT ${JWT_TOKEN}")

        if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "204" ] || [ "$HTTP_CODE" = "202" ]; then
          print_status "Docker Hub repository '$DOCKER_USERNAME/harness-demo' deleted successfully"
        elif [ "$HTTP_CODE" = "404" ]; then
          print_info "Docker Hub repository not found (may already be deleted)"
        else
          print_error "Failed to delete Docker Hub repository (HTTP $HTTP_CODE)"
          print_info "You may need to delete it manually through the Docker Hub UI"
        fi
      else
        print_error "Failed to authenticate with Docker Hub"
        print_info "Please check your Docker Hub credentials and try again"
        print_info "You can delete the repository manually at: https://hub.docker.com/repository/docker/$DOCKER_USERNAME/harness-demo"
      fi
    else
      print_info "Skipping Docker Hub repository deletion (user cancelled)"
    fi
  fi
fi

# Delete Configuration Files (optional)
if [ "$DELETE_CONFIG_FILES" = true ]; then
  print_section "Deleting Configuration Files"

  # Prompt for confirmation
  echo ""
  echo -e "${YELLOW}WARNING: This will delete local configuration and state files:${NC}"
  echo "  - .demo-config (cached credentials)"
  echo "  - kit/se-parms.tfvars (Terraform variables)"
  echo "  - kit/terraform.tfstate* (IaC state files)"
  echo "  - kit/.terraform/ (IaC working directory)"
  echo "  - kit/*.tfplan (Terraform plan files)"
  echo ""
  echo "After deletion, you will need to re-enter credentials on next run."
  echo ""
  read -p "Are you sure you want to delete these files? (yes/no): " CONFIRM_CONFIG

  if [ "$CONFIRM_CONFIG" = "yes" ]; then
    FILES_DELETED=false

    if [ -f ".demo-config" ]; then
      rm -f .demo-config
      print_status "Deleted .demo-config"
      FILES_DELETED=true
    fi

    if [ -f "kit/se-parms.tfvars" ]; then
      rm -f kit/se-parms.tfvars
      print_status "Deleted kit/se-parms.tfvars"
      FILES_DELETED=true
    fi

    if [ -f "kit/terraform.tfstate" ]; then
      rm -f kit/terraform.tfstate
      print_status "Deleted kit/terraform.tfstate"
      FILES_DELETED=true
    fi

    if [ -f "kit/terraform.tfstate.backup" ]; then
      rm -f kit/terraform.tfstate.backup
      print_status "Deleted kit/terraform.tfstate.backup"
      FILES_DELETED=true
    fi

    if [ -d "kit/.terraform" ]; then
      rm -rf kit/.terraform
      print_status "Deleted kit/.terraform/"
      FILES_DELETED=true
    fi

    if ls kit/*.tfplan &> /dev/null; then
      rm -f kit/*.tfplan
      print_status "Deleted kit/*.tfplan files"
      FILES_DELETED=true
    fi

    if [ "$FILES_DELETED" = false ]; then
      print_info "No configuration files found to delete"
    fi
  else
    print_info "Skipping configuration file deletion (user cancelled)"
  fi
fi

# Display current status
if [ "$K8S_AVAILABLE" = true ]; then
  print_section "Current Cluster Status"
else
  print_section "Cleanup Status"
fi

if [ "$K8S_AVAILABLE" = true ]; then

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

fi  # End of K8S_AVAILABLE check for status display

# Stop cluster (optional, minikube only)
if [ "$STOP_CLUSTER" = true ] && [ "$K8S_AVAILABLE" = true ]; then
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

if [ "$K8S_AVAILABLE" = true ]; then
  echo "  ✓ Frontend deployment and service"
  echo "  ✓ Backend deployment and service"
fi

if [ "$DELETE_PROMETHEUS" = true ]; then
  echo "  ✓ Prometheus monitoring"
elif [ "$K8S_AVAILABLE" = true ]; then
  echo "  ⊘ Prometheus monitoring (still running)"
fi

if [ "$DELETE_HARNESS_PROJECT" = true ]; then
  echo "  ✓ Harness 'Base Demo' project"
else
  echo "  ⊘ Harness project (still exists)"
fi

if [ "$DELETE_DOCKER_REPO" = true ]; then
  echo "  ✓ Docker Hub repository (harness-demo)"
else
  echo "  ⊘ Docker Hub repository (still exists)"
fi

if [ "$DELETE_CONFIG_FILES" = true ]; then
  echo "  ✓ Configuration files (.demo-config, se-parms.tfvars, state files)"
else
  echo "  ⊘ Configuration files (still exist)"
fi

if [ "$STOP_CLUSTER" = true ] && [ "$K8S_TYPE" = "minikube" ]; then
  echo "  ✓ Kubernetes cluster (minikube stopped)"
elif [ "$K8S_AVAILABLE" = true ]; then
  echo "  ⊘ Kubernetes cluster (still running)"
fi

echo ""
echo "What remains:"
ANYTHING_REMAINS=false

if [ "$DELETE_PROMETHEUS" = false ] && [ "$K8S_AVAILABLE" = true ]; then
  echo "  • Prometheus monitoring (in 'monitoring' namespace)"
  ANYTHING_REMAINS=true
fi

if [ "$STOP_CLUSTER" = false ] && [ "$K8S_AVAILABLE" = true ]; then
  echo "  • Kubernetes cluster ($(kubectl config current-context))"
  ANYTHING_REMAINS=true
fi

if [ "$DELETE_HARNESS_PROJECT" = false ]; then
  echo "  • Harness 'Base Demo' project (manage via Harness UI or IaC)"
  ANYTHING_REMAINS=true
fi

if [ "$DELETE_DOCKER_REPO" = false ]; then
  echo "  • Docker Hub repository (use 'docker images' to view local images)"
  ANYTHING_REMAINS=true
fi

if [ "$DELETE_CONFIG_FILES" = false ]; then
  echo "  • Configuration files (.demo-config, kit/se-parms.tfvars, state files)"
  ANYTHING_REMAINS=true
fi

if [ "$ANYTHING_REMAINS" = false ]; then
  echo "  Nothing - complete cleanup performed!"
fi

echo ""

# Show options for additional cleanup
SUGGEST_FULL_CLEANUP=false
if [ "$DELETE_PROMETHEUS" = false ] || [ "$STOP_CLUSTER" = false ] || [ "$DELETE_HARNESS_PROJECT" = false ] || [ "$DELETE_DOCKER_REPO" = false ] || [ "$DELETE_CONFIG_FILES" = false ]; then
  SUGGEST_FULL_CLEANUP=true
fi

if [ "$SUGGEST_FULL_CLEANUP" = true ]; then
  echo "For complete cleanup of everything, run:"
  echo "  ./stop-demo.sh --full-cleanup"
  echo ""
  echo "Or select specific cleanup options:"
  if [ "$DELETE_HARNESS_PROJECT" = false ]; then
    echo "  ./stop-demo.sh --delete-harness-project    # Delete Harness project"
  fi
  if [ "$DELETE_DOCKER_REPO" = false ]; then
    echo "  ./stop-demo.sh --delete-docker-repo        # Delete Docker Hub repo"
  fi
  if [ "$DELETE_CONFIG_FILES" = false ]; then
    echo "  ./stop-demo.sh --delete-config-files       # Delete local config files"
  fi
  if [ "$DELETE_PROMETHEUS" = false ] && [ "$K8S_AVAILABLE" = true ]; then
    echo "  ./stop-demo.sh --delete-prometheus         # Delete Prometheus"
  fi
  if [ "$STOP_CLUSTER" = false ] && [ "$K8S_TYPE" = "minikube" ]; then
    echo "  ./stop-demo.sh --stop-cluster              # Stop minikube"
  fi
  echo ""
fi

print_status "Shutdown complete!"
echo ""
