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
SKIP_TERRAFORM=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --skip-docker-build)
      SKIP_DOCKER_BUILD=true
      shift
      ;;
    --skip-terraform)
      SKIP_TERRAFORM=true
      shift
      ;;
    *)
      echo -e "${RED}Unknown option: $1${NC}"
      echo "Usage: ./start-demo.sh [--skip-docker-build] [--skip-terraform]"
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

# Check if Prometheus is already deployed and running
PROMETHEUS_ALREADY_RUNNING=false
if kubectl get pods -n monitoring -l app=prometheus 2>/dev/null | grep -q "Running"; then
  print_status "Prometheus is already running"
  PROMETHEUS_ALREADY_RUNNING=true
elif kubectl get deployment -n monitoring prometheus-deployment &> /dev/null; then
  print_info "Prometheus deployment exists but not running, redeploying..."
  kubectl -n monitoring delete -f kit/prometheus.yml --ignore-not-found=true &> /dev/null
  sleep 5
  kubectl -n monitoring apply -f kit/prometheus.yml &> /dev/null
  print_status "Prometheus redeployed"
else
  print_info "Deploying Prometheus..."
  kubectl -n monitoring apply -f kit/prometheus.yml &> /dev/null
  print_status "Prometheus deployed"
fi

# Wait for Prometheus to be ready (only if we just deployed or redeployed it)
if [ "$PROMETHEUS_ALREADY_RUNNING" = false ]; then
  print_info "Waiting for Prometheus to be ready..."
  if kubectl wait --for=condition=ready pod -l app=prometheus -n monitoring --timeout=120s &> /dev/null; then
    print_status "Prometheus is ready"
  else
    # Double-check if it's actually running despite wait timeout
    if kubectl get pods -n monitoring -l app=prometheus 2>/dev/null | grep -q "Running"; then
      print_status "Prometheus is running"
    else
      print_error "Prometheus failed to start. Check with: kubectl get pods -n monitoring"
    fi
  fi
fi

# Build and push Docker images (optional)
if [ "$SKIP_DOCKER_BUILD" = false ]; then
  print_section "Building Backend Docker Image"

  print_info "Checking Docker Hub authentication..."

  # Configuration file to store username
  CONFIG_FILE=".demo-config"
  DOCKER_USERNAME=""
  LOGGED_IN_USER=""

  # Check if already logged in and get current username
  LOGGED_IN_USER=$(docker info 2>/dev/null | grep "Username:" | awk '{print $2}')

  if [ -n "$LOGGED_IN_USER" ]; then
    print_status "Already logged in to Docker Hub as: $LOGGED_IN_USER"
    DOCKER_USERNAME="$LOGGED_IN_USER"
  else
    # Try to get username from local config file
    if [ -f "$CONFIG_FILE" ]; then
      DOCKER_USERNAME=$(grep "DOCKER_USERNAME=" "$CONFIG_FILE" | cut -d'=' -f2)
      if [ -n "$DOCKER_USERNAME" ]; then
        # Check if saved username is a placeholder
        case "$DOCKER_USERNAME" in
          username|dockerhubaccountid|your-username|your-dockerhub-username|DOCKERHUB_USERNAME)
            print_info "Found placeholder username in saved config: $DOCKER_USERNAME"
            print_info "Please provide your actual Docker Hub username"
            DOCKER_USERNAME=""
            ;;
          *)
            print_info "Found saved Docker Hub username: $DOCKER_USERNAME"
            ;;
        esac
      fi
    fi

    # Try to get username from Terraform config if still not found
    if [ -z "$DOCKER_USERNAME" ] && [ -f "kit/se-parms.tfvars" ]; then
      DOCKER_USERNAME=$(grep docker_username kit/se-parms.tfvars | cut -d'"' -f2 2>/dev/null || echo "")

      # Check if username looks like a placeholder
      if [ -n "$DOCKER_USERNAME" ]; then
        case "$DOCKER_USERNAME" in
          username|dockerhubaccountid|your-username|your-dockerhub-username|DOCKERHUB_USERNAME)
            print_info "Found placeholder username in kit/se-parms.tfvars: $DOCKER_USERNAME"
            print_info "Please provide your actual Docker Hub username"
            DOCKER_USERNAME=""
            ;;
          *)
            print_info "Found Docker Hub username in kit/se-parms.tfvars: $DOCKER_USERNAME"
            ;;
        esac
      fi
    fi

    # Prompt for username if still not found or was a placeholder
    if [ -z "$DOCKER_USERNAME" ]; then
      echo ""
      read -p "Enter your Docker Hub username: " DOCKER_USERNAME

      # Validate that username is not empty
      while [ -z "$DOCKER_USERNAME" ]; do
        print_error "Username cannot be empty"
        read -p "Enter your Docker Hub username: " DOCKER_USERNAME
      done
    fi

    # Save username to config file for future runs (only if file doesn't exist yet)
    # This preserves any existing credentials that were saved by the Terraform section
    if [ ! -f "$CONFIG_FILE" ] || [ ! -s "$CONFIG_FILE" ]; then
      echo "DOCKER_USERNAME=$DOCKER_USERNAME" > "$CONFIG_FILE"
      print_info "Saved username to $CONFIG_FILE for future runs"
    fi

    # Login to Docker Hub
    echo ""
    print_info "Logging in to Docker Hub..."
    print_info "You can use your Docker Hub password or Personal Access Token (PAT)"
    print_info "To create a PAT: https://hub.docker.com/settings/security"
    echo ""

    if docker login -u "$DOCKER_USERNAME"; then
      print_status "Successfully logged in to Docker Hub"
    else
      print_error "Docker login failed. Please check your credentials and try again."
      exit 1
    fi
  fi

  # Build backend image
  print_info "Building backend Docker image (this may take a few minutes)..."
  cd backend
  if docker build -t "$DOCKER_USERNAME/harness-demo:backend-latest" . --quiet; then
    print_status "Backend image built: $DOCKER_USERNAME/harness-demo:backend-latest"
  else
    print_error "Docker build failed"
    cd ..
    exit 1
  fi

  # Push backend image
  print_info "Pushing backend image to Docker Hub..."
  if docker push "$DOCKER_USERNAME/harness-demo:backend-latest" --quiet; then
    print_status "Backend image pushed to Docker Hub"
  else
    print_error "Docker push failed. Check that you have access to docker.io/$DOCKER_USERNAME/harness-demo"
    cd ..
    exit 1
  fi
  cd ..
else
  print_info "Skipping Docker image build (--skip-docker-build flag used)"
fi

# Configure and run Terraform
if [ "$SKIP_TERRAFORM" = false ]; then
  print_section "Configuring Harness Resources"

  # Configuration file
  CONFIG_FILE=".demo-config"

  # Collect required variables (or load from cache)
  HARNESS_ACCOUNT_ID=""
  HARNESS_PAT=""
  DOCKER_PASSWORD=""

  print_info "Checking cached credentials..."
  echo ""

  # Get Harness Account ID
  # Try to get account_id from config file first
  if [ -f "$CONFIG_FILE" ]; then
    HARNESS_ACCOUNT_ID=$(grep "HARNESS_ACCOUNT_ID=" "$CONFIG_FILE" | cut -d'=' -f2)
  fi

  # Try to get from se-parms.tfvars if not found
  if [ -z "$HARNESS_ACCOUNT_ID" ] && [ -f "kit/se-parms.tfvars" ]; then
    HARNESS_ACCOUNT_ID=$(grep account_id kit/se-parms.tfvars | cut -d'"' -f2 2>/dev/null || echo "")
    # Check if it's a placeholder
    if [[ "$HARNESS_ACCOUNT_ID" == *"harness account id"* ]] || [[ "$HARNESS_ACCOUNT_ID" == *"VEuU4vZ6QmSJZcgvnccqYQ"* ]]; then
      HARNESS_ACCOUNT_ID=""
    fi
  fi

  # Prompt if not found
  if [ -z "$HARNESS_ACCOUNT_ID" ]; then
    echo "Your Harness Account ID can be found in the URL when viewing your profile"
    echo "Example: https://app.harness.io/ng/account/VEuU4vZ6QmSJZcgvnccqYQ/settings/overview"
    echo "         (the ID is: VEuU4vZ6QmSJZcgvnccqYQ)"
    echo ""
    read -p "Enter your Harness Account ID: " HARNESS_ACCOUNT_ID

    while [ -z "$HARNESS_ACCOUNT_ID" ]; do
      print_error "Account ID cannot be empty"
      read -p "Enter your Harness Account ID: " HARNESS_ACCOUNT_ID
    done
  else
    print_status "Using cached Harness Account ID: $HARNESS_ACCOUNT_ID"
  fi

  # Get Harness PAT
  # Check environment variable first
  if [ -n "$DEMO_BASE_PAT" ]; then
    HARNESS_PAT="$DEMO_BASE_PAT"
    print_status "Using Harness PAT from DEMO_BASE_PAT environment variable"
  else
    # Try to get from config file
    if [ -f "$CONFIG_FILE" ]; then
      HARNESS_PAT=$(grep "HARNESS_PAT=" "$CONFIG_FILE" | cut -d'=' -f2)
    fi

    # Prompt if not found
    if [ -z "$HARNESS_PAT" ]; then
      echo ""
      echo "You need a Harness Personal Access Token (PAT)"
      echo "To create one: Profile > My API Keys & Tokens > + New Token"
      echo "Token permissions needed: All resources, all scopes"
      echo ""
      read -p "Enter your Harness PAT: " HARNESS_PAT

      while [ -z "$HARNESS_PAT" ]; do
        print_error "PAT cannot be empty"
        read -p "Enter your Harness PAT: " HARNESS_PAT
      done
    else
      print_status "Using cached Harness PAT"
    fi
  fi

  # Get Docker password/PAT
  # Try to get from config file first
  if [ -f "$CONFIG_FILE" ]; then
    DOCKER_PASSWORD=$(grep "DOCKER_PASSWORD=" "$CONFIG_FILE" | cut -d'=' -f2)
  fi

  # Check if we're logged in to Docker Hub
  LOGGED_IN_USER=$(docker info 2>/dev/null | grep "Username:" | awk '{print $2}')
  if [ -n "$LOGGED_IN_USER" ]; then
    # Already logged in - we can use a placeholder for Terraform but keep any cached PAT
    if [ -z "$DOCKER_PASSWORD" ] || [ "$DOCKER_PASSWORD" = "logged-in-via-docker-desktop" ]; then
      print_status "Docker Hub password not needed (already logged in)"
      DOCKER_PASSWORD="logged-in-via-docker-desktop"
    else
      print_status "Docker Hub password cached (logged in via Docker Desktop)"
    fi
  else
    # Not logged in via Docker Desktop - need actual password
    if [ -n "$DOCKER_PASSWORD" ] && [ "$DOCKER_PASSWORD" != "logged-in-via-docker-desktop" ]; then
      print_status "Using cached Docker Hub password/PAT"
    else
      # No valid cached password, need to prompt
      echo ""
      echo "Enter your Docker Hub password or Personal Access Token (PAT)"
      echo "To create a PAT: https://hub.docker.com/settings/security"
      echo ""
      read -sp "Docker Hub password/PAT: " DOCKER_PASSWORD
      echo ""

      while [ -z "$DOCKER_PASSWORD" ]; do
        print_error "Password/PAT cannot be empty"
        read -sp "Docker Hub password/PAT: " DOCKER_PASSWORD
        echo ""
      done
    fi
  fi

  # Save configuration for future runs
  {
    echo "DOCKER_USERNAME=$DOCKER_USERNAME"
    echo "HARNESS_ACCOUNT_ID=$HARNESS_ACCOUNT_ID"
    echo "HARNESS_PAT=$HARNESS_PAT"
    echo "DOCKER_PASSWORD=$DOCKER_PASSWORD"
  } > "$CONFIG_FILE"
  print_status "Saved credentials to $CONFIG_FILE for future runs"
  echo ""

  # Update se-parms.tfvars
  print_info "Updating kit/se-parms.tfvars..."
  cat > kit/se-parms.tfvars <<EOF
account_id = "$HARNESS_ACCOUNT_ID"

docker_username = "$DOCKER_USERNAME"
docker_password = "$DOCKER_PASSWORD"
EOF
  print_status "Updated se-parms.tfvars with your configuration"

  # Check if Terraform has already been applied
  if [ -f "kit/terraform.tfstate" ] && [ -s "kit/terraform.tfstate" ]; then
    echo ""
    print_status "IaC state already exists - Harness resources appear to be configured"
    print_info "To reconfigure, delete kit/terraform.tfstate or run: cd kit && tofu/terraform destroy"
    echo ""
  else

    # Detect and select IaC tool (OpenTofu or Terraform)
    print_section "Detecting Infrastructure as Code Tool"

    TOFU_CMD=""

    # Check for terraform first (backward compatibility)
    if command -v terraform &> /dev/null; then
      TOFU_CMD="terraform"
      print_status "Found Terraform: $(terraform version | head -n1)"
      print_info "Using Terraform (backward compatibility)"
    # Check for tofu (OpenTofu - preferred)
    elif command -v tofu &> /dev/null; then
      TOFU_CMD="tofu"
      print_status "Found OpenTofu: $(tofu version | head -n1)"
      print_info "Using OpenTofu"
    else
      # Neither found - prompt to install OpenTofu
      print_error "Neither OpenTofu nor Terraform is installed"
      echo ""
      echo "This demo requires an Infrastructure as Code tool to provision Harness resources."
      echo "We recommend OpenTofu (open-source Terraform alternative)."
      echo ""
      echo "Installation options:"
      echo ""
      echo "macOS (Homebrew):"
      echo "  brew install opentofu"
      echo ""
      echo "Linux (snap):"
      echo "  snap install --classic opentofu"
      echo ""
      echo "Windows (Chocolatey):"
      echo "  choco install opentofu"
      echo ""
      echo "For other installation methods, visit: https://opentofu.org/docs/intro/install/"
      echo ""
      read -p "Would you like to install OpenTofu now? (y/n): " INSTALL_TOFU

      if [[ "$INSTALL_TOFU" =~ ^[Yy]$ ]]; then
        echo ""
        print_info "Attempting to install OpenTofu via Homebrew..."

        if command -v brew &> /dev/null; then
          if brew install opentofu; then
            print_status "OpenTofu installed successfully"
            TOFU_CMD="tofu"
          else
            print_error "OpenTofu installation failed"
            echo "Please install OpenTofu manually and run this script again."
            cd ..
            exit 1
          fi
        else
          print_error "Homebrew not found. Please install OpenTofu manually:"
          echo "  Visit: https://opentofu.org/docs/intro/install/"
          cd ..
          exit 1
        fi
      else
        echo ""
        print_info "Setup cannot continue without OpenTofu or Terraform"
        echo "Please install one of the following and run this script again:"
        echo "  - OpenTofu (recommended): https://opentofu.org/docs/intro/install/"
        echo "  - Terraform: https://www.terraform.io/downloads"
        cd ..
        exit 1
      fi
    fi

    # Run IaC tool
    print_section "Running $TOFU_CMD"

    cd kit

    # Initialize
    print_info "Running $TOFU_CMD init..."
    if $TOFU_CMD init &> /dev/null; then
      print_status "$TOFU_CMD initialized"
    else
      print_error "$TOFU_CMD init failed"
      cd ..
      exit 1
    fi

    # Plan
    print_info "Running $TOFU_CMD plan (this may take 1-2 minutes)..."
    if $TOFU_CMD plan -var="pat=$HARNESS_PAT" -var-file="se-parms.tfvars" -out=plan.tfplan &> /dev/null; then
      print_status "$TOFU_CMD plan created"
    else
      print_error "$TOFU_CMD plan failed. Run manually to see errors: cd kit && $TOFU_CMD plan -var=\"pat=$HARNESS_PAT\" -var-file=\"se-parms.tfvars\""
      cd ..
      exit 1
    fi

    # Apply
    print_info "Running $TOFU_CMD apply (this may take 3-5 minutes)..."
    if $TOFU_CMD apply -auto-approve plan.tfplan; then
      print_status "$TOFU_CMD apply completed - Harness resources created!"
    else
      print_error "$TOFU_CMD apply failed"
      cd ..
      exit 1
    fi

    cd ..
    echo ""
  fi
else
  print_info "Skipping Terraform setup (--skip-terraform flag used)"
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

if [ "$SKIP_TERRAFORM" = true ]; then
  echo "To complete setup, run Terraform manually or rerun without --skip-terraform:"
  echo "  ./start-demo.sh"
  echo ""
elif [ -f "kit/terraform.tfstate" ] && [ -s "kit/terraform.tfstate" ]; then
  echo "✅ Harness resources are configured and ready!"
  echo ""
  echo "Next steps:"
  echo "  1. Navigate to Harness UI: https://app.harness.io"
  echo "  2. Select the 'Base Demo' project"
  echo "  3. Configure Harness Code Repository:"
  echo "     - Go to Code Repository module"
  echo "     - Click 'partner_demo_kit' repository"
  echo "     - Click 'Clone' > '+Generate Clone Credential'"
  echo "     - Save the username and token"
  echo "     - Enable Secret Scanning: Manage Repository > Security"
  echo "  4. Follow the lab guides in the markdown/ directory"
  echo ""
else
  echo "Note: Harness resources were not configured (terraform.tfstate not found)"
  echo "This may happen if terraform apply was skipped or failed."
  echo ""
  echo "To configure Harness resources, run this script again:"
  echo "  ./start-demo.sh --skip-docker-build"
  echo ""
fi

if [ "$K8S_TYPE" = "minikube" ]; then
  echo "⚠️  IMPORTANT for minikube users:"
  echo "     Run this in a separate terminal and keep it running:"
  echo "     minikube tunnel"
  echo ""
fi

print_status "Startup complete!"
echo ""
