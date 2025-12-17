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

# Save original argument count
ORIGINAL_ARG_COUNT=$#

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
      DELETE_CONFIG_FILES=false
      shift
      ;;
    *)
      echo -e "${RED}Unknown option: $1${NC}"
      echo "Usage: ./stop-demo.sh [OPTIONS]"
      echo "  --delete-prometheus       Delete Prometheus monitoring"
      echo "  --stop-cluster            Stop Kubernetes cluster (minikube only)"
      echo "  --delete-harness-project  Delete Harness 'Base Demo' project"
      echo "  --delete-docker-repo      Delete Docker Hub repository"
      echo "  --delete-config-files     Delete config and state files (.demo-config, terraform state)"
      echo "  --full-cleanup            Everything except credentials (stops cluster, keeps credentials)"
      echo ""
      echo "Default (no options): Cleanup all resources but keep cluster running and preserve credentials"
      exit 1
      ;;
  esac
done

# If no arguments provided, default to cleanup (but keep cluster running and preserve credentials)
if [ "$ORIGINAL_ARG_COUNT" -eq 0 ]; then
  echo -e "${YELLOW}No options provided - defaulting to cleanup (keeping cluster running, preserving credentials)${NC}"
  echo ""
  DELETE_PROMETHEUS=true
  STOP_CLUSTER=false
  DELETE_HARNESS_PROJECT=true
  DELETE_DOCKER_REPO=true
  DELETE_CONFIG_FILES=false
fi

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

# Delete all application deployments (including canary deployments created by pipeline)
print_info "Checking for application deployments in default namespace..."
ALL_DEPLOYMENTS=$(kubectl get deployments -n default --no-headers 2>/dev/null | grep -E "frontend|backend|docs" | awk '{print $1}')

if [ -n "$ALL_DEPLOYMENTS" ]; then
  print_info "Found deployments to delete:"
  echo "$ALL_DEPLOYMENTS" | while read -r deployment; do
    echo "  - $deployment"
  done

  echo "$ALL_DEPLOYMENTS" | while read -r deployment; do
    print_info "Deleting deployment: $deployment"
    kubectl delete deployment "$deployment" -n default --ignore-not-found=true
  done
  print_status "All application deployments deleted"
else
  print_info "No application deployments found"
fi

# Delete all application services (including those created by pipeline)
print_info "Checking for application services in default namespace..."
ALL_SERVICES=$(kubectl get services -n default --no-headers 2>/dev/null | grep -E "frontend|backend|docs" | awk '{print $1}')

if [ -n "$ALL_SERVICES" ]; then
  print_info "Found services to delete:"
  echo "$ALL_SERVICES" | while read -r service; do
    echo "  - $service"
  done

  echo "$ALL_SERVICES" | while read -r service; do
    print_info "Deleting service: $service"
    kubectl delete service "$service" -n default --ignore-not-found=true
  done
  print_status "All application services deleted"
else
  print_info "No application services found"
fi

# Delete any remaining pods and wait for full termination
print_info "Checking for remaining application pods in default namespace..."
REMAINING_PODS=$(kubectl get pods -n default --no-headers 2>/dev/null | grep -E "frontend|backend|docs" | wc -l)
if [ "$REMAINING_PODS" -gt 0 ]; then
  print_info "Waiting for $REMAINING_PODS pod(s) to fully terminate..."

  # Show which pods are terminating
  kubectl get pods -n default --no-headers 2>/dev/null | grep -E "frontend|backend|docs" | awk '{print "  - " $1 " (" $3 ")"}'

  # Wait up to 90 seconds for pods to terminate (increased from 60 for canary cleanup)
  WAIT_TIME=0
  MAX_WAIT=90
  while [ $WAIT_TIME -lt $MAX_WAIT ]; do
    REMAINING=$(kubectl get pods -n default --no-headers 2>/dev/null | grep -E "frontend|backend|docs" | wc -l)
    if [ "$REMAINING" -eq 0 ]; then
      break
    fi
    sleep 2
    WAIT_TIME=$((WAIT_TIME + 2))
  done

  FINAL_COUNT=$(kubectl get pods -n default --no-headers 2>/dev/null | grep -E "frontend|backend|docs" | wc -l)
  if [ "$FINAL_COUNT" -eq 0 ]; then
    print_status "All application pods terminated"
  else
    print_info "$FINAL_COUNT pod(s) still terminating (may take 1-2 full minutes)"
    kubectl get pods -n default --no-headers 2>/dev/null | grep -E "frontend|backend|docs" | awk '{print "  - " $1 " (" $3 ")"}'
  fi
else
  print_status "No application pods found"
fi

# Delete Harness Delegate namespace and resources
print_section "Cleaning Up Harness Delegate"
if kubectl get namespace harness-delegate-ng &> /dev/null; then
  print_info "Found harness-delegate-ng namespace"

  # Delete all deployments in the delegate namespace
  DELEGATE_DEPLOYMENTS=$(kubectl get deployments -n harness-delegate-ng --no-headers 2>/dev/null | awk '{print $1}')
  if [ -n "$DELEGATE_DEPLOYMENTS" ]; then
    print_info "Deleting delegate deployments..."
    echo "$DELEGATE_DEPLOYMENTS" | while read -r deployment; do
      kubectl delete deployment "$deployment" -n harness-delegate-ng --ignore-not-found=true
    done
    print_status "Delegate deployments deleted"
  fi

  # Wait for delegate pods to terminate
  print_info "Waiting for delegate pods to terminate..."
  WAIT_TIME=0
  MAX_WAIT=60
  while [ $WAIT_TIME -lt $MAX_WAIT ]; do
    DELEGATE_PODS=$(kubectl get pods -n harness-delegate-ng --no-headers 2>/dev/null | wc -l)
    if [ "$DELEGATE_PODS" -eq 0 ]; then
      break
    fi
    sleep 2
    WAIT_TIME=$((WAIT_TIME + 2))
  done

  # Delete the namespace
  print_info "Deleting harness-delegate-ng namespace..."
  kubectl delete namespace harness-delegate-ng --ignore-not-found=true &> /dev/null || true
  print_status "Harness delegate namespace deleted"
else
  print_info "Harness delegate namespace not found (already deleted)"
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

  # Load credentials
  if [ -f ".demo-config" ]; then
    source .demo-config
  fi
  if [ -f "kit/se-parms.tfvars" ]; then
    HARNESS_ACCOUNT_ID=$(grep 'account_id' kit/se-parms.tfvars | cut -d'"' -f2)
  fi
  if [ -z "$HARNESS_PAT" ]; then
    HARNESS_PAT="${DEMO_BASE_PAT}"
  fi

  # Check if IaC state file exists
  if [ ! -f "kit/terraform.tfstate" ] || [ ! -s "kit/terraform.tfstate" ]; then
    print_info "No Terraform state file found"
    print_info "Will attempt to delete 'Base Demo' project directly via Harness API..."
    echo ""

    # Try API deletion directly (no terraform)
    if [ -n "$HARNESS_ACCOUNT_ID" ] && [ -n "$HARNESS_PAT" ]; then
      print_info "Account: ${HARNESS_ACCOUNT_ID}"
      print_info "Project: Base_Demo"
      echo ""

      print_info "Deleting 'Base Demo' project via API..."
      PROJECT_DELETE_RESPONSE=$(curl -s -w "\n%{http_code}" -X DELETE \
        "https://app.harness.io/ng/api/projects/Base_Demo?accountIdentifier=${HARNESS_ACCOUNT_ID}&orgIdentifier=default" \
        -H "x-api-key: ${HARNESS_PAT}" \
        -H "Content-Type: application/json" 2>&1)

      PROJECT_HTTP_CODE=$(echo "$PROJECT_DELETE_RESPONSE" | tail -n 1)
      PROJECT_RESPONSE_BODY=$(echo "$PROJECT_DELETE_RESPONSE" | head -n -1)

      echo "HTTP Status Code: $PROJECT_HTTP_CODE"
      echo ""

      if [ "$PROJECT_HTTP_CODE" = "200" ] || [ "$PROJECT_HTTP_CODE" = "204" ]; then
        print_status "Base Demo project deleted successfully"
      elif [ "$PROJECT_HTTP_CODE" = "404" ]; then
        print_info "Project not found (already deleted)"
      else
        print_error "Failed to delete project (HTTP $PROJECT_HTTP_CODE)"
        if [ -n "$PROJECT_RESPONSE_BODY" ]; then
          echo "API Response: $PROJECT_RESPONSE_BODY" | head -n 3
        fi
      fi
    else
      print_error "Missing credentials (HARNESS_ACCOUNT_ID or HARNESS_PAT)"
      print_info "Cannot delete project without credentials"
    fi
  else
    # We have a state file, use IaC to destroy
    print_info "Found Terraform state file"
    echo ""
    echo -e "${YELLOW}Will delete all Harness resources via Terraform:${NC}"
    echo "  - 'Base Demo' project"
    echo "  - Code repositories"
    echo "  - Pipelines"
    echo "  - Services"
    echo "  - Environments"
    echo "  - Connectors"
    echo ""

    # Accept y/Y/yes as confirmation (no prompt needed for full cleanup)
    CONFIRM_HARNESS="yes"
    if [[ "$CONFIRM_HARNESS" =~ ^[Yy]([Ee][Ss])?$ ]]; then
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
        # First, delete the pipeline to remove references to connectors, templates, etc.
        if [ -n "$HARNESS_ACCOUNT_ID" ] && [ -n "$HARNESS_PAT" ]; then
          print_section "Deleting Harness Pipeline"
          print_info "Deleting 'Workshop Build and Deploy' pipeline..."

          # Try to delete the pipeline via API
          PIPELINE_DELETE_RESPONSE=$(curl -s -w "\n%{http_code}" -X DELETE \
            "https://app.harness.io/pipeline/api/pipelines/Workshop_Build_and_Deploy?accountIdentifier=${HARNESS_ACCOUNT_ID}&orgIdentifier=default&projectIdentifier=Base_Demo" \
            -H "x-api-key: ${HARNESS_PAT}" 2>/dev/null)

          HTTP_CODE=$(echo "$PIPELINE_DELETE_RESPONSE" | tail -n 1)

          if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "204" ]; then
            print_status "Pipeline deleted successfully"
          elif [ "$HTTP_CODE" = "404" ]; then
            print_info "Pipeline not found (may already be deleted or not created yet)"
          else
            print_info "Could not delete pipeline via API (HTTP $HTTP_CODE)"
            print_info "This is OK if the pipeline doesn't exist yet"
          fi

          # Wait a moment for Harness to process the deletion
          sleep 2
        fi

        # Check for Terraform
        if ! command -v terraform &> /dev/null; then
          print_error "Terraform not found"
          print_info "Cannot destroy Harness resources without Terraform"
          print_info "Please install Terraform, or delete resources manually through Harness UI"
        else
          print_section "Running Terraform Destroy"
          print_status "Using Terraform for destroy"
          print_info "Running terraform destroy (this may take 2-3 minutes)..."

          cd kit
          TERRAFORM_SUCCESS=false
          if terraform destroy -var="pat=$HARNESS_PAT" -var-file="se-parms.tfvars" -auto-approve; then
            print_status "Harness resources destroyed successfully via Terraform"
            TERRAFORM_SUCCESS=true
          else
            print_error "Terraform destroy encountered errors"
            print_info "Some resources may have been deleted. Check kit/terraform.tfstate"
            print_info ""

            # Offer to delete the entire project via API as fallback
            echo ""
            echo -e "${YELLOW}Terraform couldn't delete all resources due to dependencies.${NC}"
            echo -e "${YELLOW}Would you like to delete the entire 'Base Demo' project via Harness API?${NC}"
            echo "This will forcefully delete the project and all its resources."
            echo ""
            read -p "Delete 'Base Demo' project via API? [Y/n]: " DELETE_PROJECT_API

            # Default to yes if empty
            DELETE_PROJECT_API=${DELETE_PROJECT_API:-yes}

            # Accept y/Y/yes as confirmation
            if [[ "$DELETE_PROJECT_API" =~ ^[Yy]([Ee][Ss])?$ ]]; then
              print_section "Deleting Project via Harness API"

              print_info "Account: ${HARNESS_ACCOUNT_ID}"
              print_info "Org: default"
              print_info "Project: Base_Demo"
              echo ""

              print_info "Deleting 'Base Demo' project (cascade delete all resources)..."

              # Delete the entire Base Demo project with verbose output
              PROJECT_DELETE_RESPONSE=$(curl -s -w "\n%{http_code}" -X DELETE \
                "https://app.harness.io/ng/api/projects/Base_Demo?accountIdentifier=${HARNESS_ACCOUNT_ID}&orgIdentifier=default" \
                -H "x-api-key: ${HARNESS_PAT}" \
                -H "Content-Type: application/json" \
                -H "Accept: application/json" 2>&1)

              PROJECT_HTTP_CODE=$(echo "$PROJECT_DELETE_RESPONSE" | tail -n 1)
              PROJECT_RESPONSE_BODY=$(echo "$PROJECT_DELETE_RESPONSE" | head -n -1)

              echo ""
              echo "HTTP Status Code: $PROJECT_HTTP_CODE"

              if [ "$PROJECT_HTTP_CODE" = "200" ] || [ "$PROJECT_HTTP_CODE" = "204" ]; then
                print_status "Base Demo project deleted successfully"
                echo ""
                echo "Project and all its resources have been deleted:"
                echo "  - Services"
                echo "  - Environments"
                echo "  - Pipelines"
                echo "  - Connectors"
                echo "  - Monitored services"
                echo "  - All other project resources"
                TERRAFORM_SUCCESS=true
              elif [ "$PROJECT_HTTP_CODE" = "404" ]; then
                print_info "Project not found (already deleted)"
                TERRAFORM_SUCCESS=true
              else
                print_error "Failed to delete project (HTTP $PROJECT_HTTP_CODE)"
                echo ""
                if [ -n "$PROJECT_RESPONSE_BODY" ]; then
                  echo "API Response Body:"
                  echo "----------------------------------------"
                  echo "$PROJECT_RESPONSE_BODY"
                  echo "----------------------------------------"
                fi
                echo ""
                print_info "Manual deletion required via Harness UI:"
                print_info "  1. Navigate to: Projects > Base Demo"
                print_info "  2. Click the three dots (⋮) menu"
                print_info "  3. Select 'Delete Project'"
                print_info "  4. Confirm deletion"
              fi
            else
              print_info "Skipping API deletion"
              print_info ""
              print_info "To retry terraform destroy:"
              print_info "  cd kit && terraform destroy -var=\"pat=\$DEMO_BASE_PAT\" -var-file=\"se-parms.tfvars\""
              print_info ""
              print_info "Or delete manually in Harness UI:"
              print_info "  Navigate to Projects > Base Demo > ⋮ > Delete Project"
            fi
          fi
          cd ..

          # Clean up terraform state files if deletion was successful
          if [ "$TERRAFORM_SUCCESS" = true ]; then
            print_info "Cleaning up Terraform state files..."
            if [ -f "kit/terraform.tfstate" ]; then
              rm -f kit/terraform.tfstate
              rm -f kit/terraform.tfstate.backup
              print_status "Terraform state files removed"
            fi
          fi
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
    read -p "Are you sure you want to delete this Docker Hub repository? [Y/n]: " CONFIRM_DOCKER

    # Default to yes if empty
    CONFIRM_DOCKER=${CONFIRM_DOCKER:-yes}

    # Accept y/Y/yes as confirmation
    if [[ "$CONFIRM_DOCKER" =~ ^[Yy]([Ee][Ss])?$ ]]; then
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
  read -p "Are you sure you want to delete these files? [Y/n]: " CONFIRM_CONFIG

  # Default to yes if empty
  CONFIRM_CONFIG=${CONFIRM_CONFIG:-yes}

  # Accept y/Y/yes as confirmation
  if [[ "$CONFIRM_CONFIG" =~ ^[Yy]([Ee][Ss])?$ ]]; then
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
  echo "For additional cleanup options:"
  echo ""
  echo "Clean everything (keeps credentials):"
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
