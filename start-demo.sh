#!/bin/bash
#
# Harness Partner Demo Kit - Startup Script
#
# This script sets up and starts all local infrastructure needed for the demo:
# - Kubernetes cluster (platform-specific):
#   * macOS (Apple Silicon): Colima with Rosetta 2 for AMD64 emulation
#   * macOS (Intel): minikube, Rancher Desktop, Docker Desktop, or Colima
#   * Windows: minikube, Rancher Desktop, or Docker Desktop
#   * Linux: minikube or other K8s distributions
# - Prometheus monitoring
# - Docker image builds (backend, test, docs) with automatic architecture detection
#   * Detects Apple Silicon (ARM64) and builds for amd64 (Harness Cloud compatibility)
#   * Intel/AMD builds natively without platform override
# - Harness resource provisioning via Terraform
#
# Usage: ./start-demo.sh [--skip-docker-build] [--skip-terraform]
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

# Detect Operating System and Architecture
print_section "Detecting Platform"

OS_TYPE="unknown"
ARCH=$(uname -m)

case "$(uname -s)" in
  Darwin*)
    OS_TYPE="macos"
    print_status "Operating System: macOS"
    ;;
  Linux*)
    OS_TYPE="linux"
    print_status "Operating System: Linux"
    ;;
  MINGW*|MSYS*|CYGWIN*)
    OS_TYPE="windows"
    print_status "Operating System: Windows (Git Bash/MSYS/Cygwin)"
    print_info "See README.md 'Windows Users' section for setup guidance"
    ;;
  *)
    print_error "Unknown operating system: $(uname -s)"
    exit 1
    ;;
esac

print_info "Architecture: $ARCH"

# Check for required Kubernetes tool based on OS and architecture
print_section "Checking Kubernetes Tool"

K8S_TOOL_MISSING=false
RECOMMENDED_TOOL=""

if [ "$OS_TYPE" = "macos" ] && ([ "$ARCH" = "arm64" ] || [ "$ARCH" = "aarch64" ]); then
  # Apple Silicon Mac - require Colima for AMD64 emulation via Rosetta 2
  RECOMMENDED_TOOL="Colima"
  if ! command -v colima &> /dev/null; then
    print_error "Colima is not installed (required for Apple Silicon Macs)"
    echo ""
    echo "Apple Silicon Macs require Colima with Rosetta 2 for AMD64 emulation."
    echo "This is necessary because Harness Cloud builds AMD64 images."
    echo ""
    echo "To install Colima:"
    echo "  brew install colima docker kubectl"
    echo ""
    echo "To start Colima with AMD64 emulation:"
    echo "  colima start --vm-type=vz --vz-rosetta --arch x86_64 --cpu 4 --memory 8 --kubernetes"
    echo ""
    echo "Note: First startup may take 5-10 minutes while downloading images."
    echo ""
    K8S_TOOL_MISSING=true
  else
    print_status "Colima is installed"
    # Check if Colima is running
    if colima status &> /dev/null; then
      # Check if running with correct architecture
      # Note: colima status outputs to stderr, so we need 2>&1
      COLIMA_ARCH=$(colima status 2>&1 | grep "arch:" | sed 's/.*msg="arch: //' | sed 's/".*//')
      if [ "$COLIMA_ARCH" = "x86_64" ] || [ "$COLIMA_ARCH" = "amd64" ]; then
        print_status "Colima is running with AMD64 emulation (Rosetta 2)"
      else
        print_error "Colima is running but not with AMD64 architecture (currently: $COLIMA_ARCH)"
        echo ""
        echo "Colima must be restarted with AMD64 emulation."
        echo "This requires stopping and recreating the Colima VM."
        echo ""
        read -p "Stop and restart Colima with AMD64 emulation? [Y/n]: " RESTART_COLIMA
        RESTART_COLIMA=${RESTART_COLIMA:-yes}

        if [[ "$RESTART_COLIMA" =~ ^[Yy]([Ee][Ss])?$ ]]; then
          print_info "Stopping Colima..."
          colima stop
          print_info "Deleting Colima VM..."
          colima delete
          print_info "Starting Colima with AMD64 emulation (this may take 5-10 minutes)..."
          colima start --vm-type=vz --vz-rosetta --arch x86_64 --cpu 4 --memory 8 --kubernetes
          print_status "Colima started successfully with AMD64 emulation"
        else
          print_error "Cannot proceed without AMD64 architecture"
          echo ""
          echo "To restart manually:"
          echo "  colima stop && colima delete"
          echo "  colima start --vm-type=vz --vz-rosetta --arch x86_64 --cpu 4 --memory 8 --kubernetes"
          echo ""
          K8S_TOOL_MISSING=true
        fi
      fi
    else
      print_info "Colima is not running - starting it now..."
      echo ""
      print_info "Starting Colima with AMD64 emulation (this may take 5-10 minutes on first run)..."
      if colima start --vm-type=vz --vz-rosetta --arch x86_64 --cpu 4 --memory 8 --kubernetes; then
        print_status "Colima started successfully"
      else
        print_error "Failed to start Colima"
        echo ""
        echo "Please try starting manually:"
        echo "  colima start --vm-type=vz --vz-rosetta --arch x86_64 --cpu 4 --memory 8 --kubernetes"
        echo ""
        K8S_TOOL_MISSING=true
      fi
    fi
  fi
elif [ "$OS_TYPE" = "windows" ]; then
  # Windows - recommend minikube but allow other options
  RECOMMENDED_TOOL="minikube"
  if ! command -v minikube &> /dev/null; then
    print_info "minikube is not installed (recommended for Windows)"
    echo ""
    echo "For Windows, we recommend minikube for running Kubernetes locally."
    echo ""
    echo "To install minikube:"
    echo "  Visit: https://minikube.sigs.k8s.io/docs/start/"
    echo ""
    echo "Alternative options:"
    echo "  - Docker Desktop with Kubernetes enabled"
    echo "  - Rancher Desktop with Kubernetes enabled"
    echo ""
    read -p "Do you have Docker Desktop or Rancher Desktop with Kubernetes? [y/N]: " HAS_ALTERNATIVE
    if [[ ! "$HAS_ALTERNATIVE" =~ ^[Yy]$ ]]; then
      print_error "No Kubernetes tool detected. Please install one of the options above."
      K8S_TOOL_MISSING=true
    else
      print_info "Proceeding with alternative Kubernetes tool"
    fi
  else
    print_status "minikube is installed"
  fi
else
  # macOS Intel or Linux - flexible options
  if [ "$OS_TYPE" = "macos" ]; then
    RECOMMENDED_TOOL="minikube, Colima, Docker Desktop, or Rancher Desktop"
  else
    RECOMMENDED_TOOL="minikube or your preferred K8s distribution"
  fi

  # Check for common tools
  if command -v minikube &> /dev/null; then
    print_status "minikube is installed"
  elif command -v colima &> /dev/null; then
    print_status "Colima is installed"
  elif kubectl config current-context 2>/dev/null | grep -q "docker-desktop"; then
    print_status "Docker Desktop with Kubernetes detected"
  elif kubectl config current-context 2>/dev/null | grep -q "rancher-desktop"; then
    print_status "Rancher Desktop detected"
  else
    print_info "No common Kubernetes tool detected"
    echo ""
    echo "Please ensure you have one of the following installed and running:"
    echo "  - minikube: https://minikube.sigs.k8s.io/docs/start/"
    echo "  - Colima: brew install colima"
    echo "  - Docker Desktop: https://www.docker.com/products/docker-desktop/"
    echo "  - Rancher Desktop: https://rancherdesktop.io/"
    echo ""
    read -p "Do you have Kubernetes running with kubectl configured? [y/N]: " HAS_K8S
    if [[ ! "$HAS_K8S" =~ ^[Yy]$ ]]; then
      print_error "No Kubernetes tool detected. Please install one of the options above."
      K8S_TOOL_MISSING=true
    else
      print_info "Proceeding with your Kubernetes setup"
    fi
  fi
fi

if [ "$K8S_TOOL_MISSING" = true ]; then
  print_error "Required Kubernetes tool not found: $RECOMMENDED_TOOL"
  echo ""
  print_info "Setup instructions: see README.md or CLAUDE.md for platform-specific setup"
  exit 1
fi

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
if kubectl config current-context 2>/dev/null | grep -q "colima"; then
  K8S_TYPE="colima"
  print_status "Detected Colima"
  # Verify architecture for Colima on Apple Silicon
  if [ "$OS_TYPE" = "macos" ] && ([ "$ARCH" = "arm64" ] || [ "$ARCH" = "aarch64" ]); then
    CLUSTER_ARCH=$(kubectl get nodes -o jsonpath='{.items[0].status.nodeInfo.architecture}' 2>/dev/null)
    if [ "$CLUSTER_ARCH" = "amd64" ]; then
      print_status "Cluster is running AMD64 (correct for Harness Cloud compatibility)"
    else
      print_error "Cluster is running $CLUSTER_ARCH architecture (expected amd64)"
      echo ""
      echo "Please restart Colima with AMD64 emulation:"
      echo "  colima stop && colima delete"
      echo "  colima start --vm-type=vz --vz-rosetta --arch x86_64 --cpu 4 --memory 8 --kubernetes"
      exit 1
    fi
  fi
elif kubectl config current-context 2>/dev/null | grep -q "minikube"; then
  K8S_TYPE="minikube"
  print_status "Detected minikube"
elif kubectl config current-context 2>/dev/null | grep -q "rancher-desktop"; then
  K8S_TYPE="rancher-desktop"
  print_status "Detected Rancher Desktop"
elif kubectl config current-context 2>/dev/null | grep -q "docker-desktop"; then
  K8S_TYPE="docker-desktop"
  print_status "Detected Docker Desktop"
else
  # Try to connect to see if any cluster is available
  if kubectl cluster-info &> /dev/null; then
    K8S_TYPE="other"
    print_status "Detected Kubernetes cluster: $(kubectl config current-context)"
  else
    print_error "No Kubernetes cluster detected."
    echo ""
    if [ "$OS_TYPE" = "macos" ] && ([ "$ARCH" = "arm64" ] || [ "$ARCH" = "aarch64" ]); then
      echo "For Apple Silicon Macs, start Colima:"
      echo "  colima start --vm-type=vz --vz-rosetta --arch x86_64 --cpu 4 --memory 8 --kubernetes"
    else
      echo "Please ensure one of the following is running:"
      echo "  - minikube (run 'minikube start')"
      echo "  - Colima (run 'colima start --kubernetes')"
      echo "  - Rancher Desktop with Kubernetes enabled"
      echo "  - Docker Desktop with Kubernetes enabled"
    fi
    exit 1
  fi
fi

# Start Colima if needed
if [ "$K8S_TYPE" = "colima" ]; then
  # Colima should already be running if we got here, but verify
  if ! colima status &> /dev/null; then
    print_info "Starting Colima (this may take 5-10 minutes on first run)..."
    if [ "$OS_TYPE" = "macos" ] && ([ "$ARCH" = "arm64" ] || [ "$ARCH" = "aarch64" ]); then
      colima start --vm-type=vz --vz-rosetta --arch x86_64 --cpu 4 --memory 8 --kubernetes
    else
      colima start --cpu 4 --memory 8 --kubernetes
    fi
    print_status "Colima started successfully"
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

# Create Docker Hub secret for pulling images
print_section "Creating Docker Hub Secret for Image Pulls"

# This secret allows Kubernetes to pull Harness CI addon images (harness/ci-addon, etc.)
# Harness CI looks for a secret named 'dockerhub-pull'

# Load Docker credentials from config file
CONFIG_FILE=".demo-config"
if [ -f "$CONFIG_FILE" ]; then
  DOCKER_USERNAME=$(grep "DOCKER_USERNAME=" "$CONFIG_FILE" | cut -d'=' -f2)
  DOCKER_PAT=$(grep "DOCKER_PAT=" "$CONFIG_FILE" | cut -d'=' -f2)
fi

# Check if we have credentials
if [ -n "$DOCKER_USERNAME" ] && [ -n "$DOCKER_PAT" ] && [ "$DOCKER_PAT" != "logged-in-via-docker-desktop" ]; then
  print_info "Creating Docker Hub pull secret with saved credentials..."

  # Create secret in default namespace
  if kubectl get secret dockerhub-pull -n default &> /dev/null; then
    print_info "Updating existing Docker Hub secret in default namespace..."
    kubectl delete secret dockerhub-pull -n default &> /dev/null
  fi

  kubectl create secret docker-registry dockerhub-pull \
    --docker-server=https://index.docker.io/v1/ \
    --docker-username="$DOCKER_USERNAME" \
    --docker-password="$DOCKER_PAT" \
    --docker-email="${DOCKER_USERNAME}@example.com" \
    -n default &> /dev/null

  if [ $? -eq 0 ]; then
    print_status "Docker Hub secret created in default namespace"
  else
    print_error "Failed to create Docker Hub secret in default namespace"
  fi

  # Create secret in harness-delegate-ng namespace (if it exists)
  if kubectl get namespace harness-delegate-ng &> /dev/null; then
    if kubectl get secret dockerhub-pull -n harness-delegate-ng &> /dev/null; then
      print_info "Updating existing Docker Hub secret in harness-delegate-ng namespace..."
      kubectl delete secret dockerhub-pull -n harness-delegate-ng &> /dev/null
    fi

    kubectl create secret docker-registry dockerhub-pull \
      --docker-server=https://index.docker.io/v1/ \
      --docker-username="$DOCKER_USERNAME" \
      --docker-password="$DOCKER_PAT" \
      --docker-email="${DOCKER_USERNAME}@example.com" \
      -n harness-delegate-ng &> /dev/null

    if [ $? -eq 0 ]; then
      print_status "Docker Hub secret created in harness-delegate-ng namespace"

      # Attach secret to default service account
      kubectl patch serviceaccount default -n harness-delegate-ng -p '{"imagePullSecrets": [{"name": "dockerhub-pull"}]}' &> /dev/null
      print_status "Attached secret to default service account in harness-delegate-ng"
    else
      print_error "Failed to create Docker Hub secret in harness-delegate-ng namespace"
    fi
  else
    print_info "harness-delegate-ng namespace not found, skipping secret creation there"
  fi

  # Attach secret to default service account in default namespace
  kubectl patch serviceaccount default -n default -p '{"imagePullSecrets": [{"name": "dockerhub-pull"}]}' &> /dev/null
  print_status "Attached secret to default service account in default namespace"
else
  print_info "Docker credentials not available yet, skipping secret creation"
  print_info "The secret will be created after Docker authentication"
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
  DOCKER_LOGIN_PASSWORD=""
  LOGGED_IN_USER=""

  # Check if already logged in and get current username
  LOGGED_IN_USER=$(docker info 2>/dev/null | grep "Username:" | awk '{print $2}')

  if [ -n "$LOGGED_IN_USER" ]; then
    print_status "Detected Docker Hub session: $LOGGED_IN_USER"
  fi

  # Load cached username/password if available
  if [ -f "$CONFIG_FILE" ]; then
    DOCKER_USERNAME=$(grep "DOCKER_USERNAME=" "$CONFIG_FILE" | cut -d'=' -f2)
    DOCKER_LOGIN_PASSWORD=$(grep "DOCKER_PAT=" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2)
  fi

  if [ -n "$DOCKER_USERNAME" ]; then
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

  # Fall back to currently logged-in user if no cached username
  if [ -z "$DOCKER_USERNAME" ] && [ -n "$LOGGED_IN_USER" ]; then
    DOCKER_USERNAME="$LOGGED_IN_USER"
    print_status "Using Docker Desktop session for user: $DOCKER_USERNAME"
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

  # Load cached password/PAT
  if [ -f "$CONFIG_FILE" ]; then
    DOCKER_LOGIN_PASSWORD=$(grep "DOCKER_PAT=" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2)
  fi

  if [ -z "$DOCKER_LOGIN_PASSWORD" ] && [ -f "kit/se-parms.tfvars" ]; then
    DOCKER_LOGIN_PASSWORD=$(grep DOCKER_PAT kit/se-parms.tfvars | cut -d'"' -f2 2>/dev/null || echo "")
  fi

  if [ "$DOCKER_LOGIN_PASSWORD" = "logged-in-via-docker-desktop" ]; then
    DOCKER_LOGIN_PASSWORD=""
  fi

  NEED_DOCKER_LOGIN=false

  # If we have cached credentials, ALWAYS use them to login
  # This ensures we have a fresh auth token even if docker info shows a logged-in user
  if [ -n "$DOCKER_LOGIN_PASSWORD" ]; then
    print_status "Using cached Docker Hub credentials"
    NEED_DOCKER_LOGIN=true
  elif [ -n "$LOGGED_IN_USER" ] && [ "$LOGGED_IN_USER" = "$DOCKER_USERNAME" ]; then
    # Only trust existing session if we don't have cached credentials
    print_status "Using existing Docker Hub session for: $LOGGED_IN_USER"
    print_info "Note: If push fails, you may need to re-authenticate"
  else
    echo ""
    print_info "You need to provide your Docker Hub password or Personal Access Token (PAT)"
    print_info "To create a PAT: https://hub.docker.com/settings/security"
    echo ""
    read -sp "Enter your Docker Hub password/PAT: " DOCKER_LOGIN_PASSWORD
    echo ""

    # Validate that password is not empty
    while [ -z "$DOCKER_LOGIN_PASSWORD" ]; do
      print_error "Password/PAT cannot be empty"
      read -sp "Enter your Docker Hub password/PAT: " DOCKER_LOGIN_PASSWORD
      echo ""
    done
    NEED_DOCKER_LOGIN=true
  fi

  if [ "$NEED_DOCKER_LOGIN" = true ]; then
    echo ""
    if [ -n "$LOGGED_IN_USER" ] && [ "$LOGGED_IN_USER" != "$DOCKER_USERNAME" ]; then
      print_info "Logging in to Docker Hub as $DOCKER_USERNAME (overriding existing session)..."
    else
      print_info "Logging in to Docker Hub as $DOCKER_USERNAME..."
    fi

    # Attempt Docker login and capture any errors
    LOGIN_OUTPUT=$(echo "$DOCKER_LOGIN_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin 2>&1)
    LOGIN_EXIT_CODE=$?

    if [ $LOGIN_EXIT_CODE -eq 0 ]; then
      print_status "Successfully logged in to Docker Hub"
    else
      # Check if it's a credential helper error
      if echo "$LOGIN_OUTPUT" | grep -q "docker-credential.*executable file not found"; then
        print_info "Docker credential helper not found, configuring direct credential storage..."

        # Backup existing Docker config if it exists
        if [ -f ~/.docker/config.json ]; then
          cp ~/.docker/config.json ~/.docker/config.json.backup.$(date +%s) 2>/dev/null || true
        fi

        # Create or update Docker config to not use credential helper
        mkdir -p ~/.docker
        if [ -f ~/.docker/config.json ]; then
          # Remove credsStore from existing config
          cat ~/.docker/config.json | grep -v '"credsStore"' > ~/.docker/config.json.tmp
          mv ~/.docker/config.json.tmp ~/.docker/config.json
        else
          echo '{}' > ~/.docker/config.json
        fi

        # Retry Docker login
        print_info "Retrying Docker login..."
        if echo "$DOCKER_LOGIN_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin 2>&1; then
          print_status "Successfully logged in to Docker Hub"
        else
          print_error "Docker login failed. Please check your credentials."
          exit 1
        fi
      else
        print_error "Docker login failed: $LOGIN_OUTPUT"
        print_error "Please check your credentials and try again."
        exit 1
      fi
    fi

    # Save credentials to config file for future runs (only if file doesn't exist yet)
    # This preserves any existing credentials that were saved by the Terraform section
    if [ ! -f "$CONFIG_FILE" ] || [ ! -s "$CONFIG_FILE" ]; then
      {
        echo "DOCKER_USERNAME=$DOCKER_USERNAME"
        echo "DOCKER_PAT=$DOCKER_LOGIN_PASSWORD"
      } > "$CONFIG_FILE"
      print_info "Saved credentials to $CONFIG_FILE for future runs"
    fi
  fi

  # Detect architecture
  ARCH=$(uname -m)
  BUILD_PLATFORM=""

  if [ "$ARCH" = "arm64" ] || [ "$ARCH" = "aarch64" ]; then
    print_info "Detected Apple Silicon (ARM64) - building for amd64 (Harness Cloud compatibility)"
    BUILD_PLATFORM="linux/amd64"
    BUILD_CMD="docker buildx build --platform $BUILD_PLATFORM"
    PUSH_FLAG="--push"
  else
    print_info "Detected Intel/AMD architecture - building natively"
    BUILD_CMD="docker build"
    PUSH_FLAG=""
  fi

  # Build backend image
  print_info "Building backend Docker image (this may take a few minutes)..."
  cd backend
  if [ -n "$PUSH_FLAG" ]; then
    # Use buildx with --push for ARM64
    if $BUILD_CMD -t "$DOCKER_USERNAME/harness-demo:backend-latest" $PUSH_FLAG . --quiet; then
      print_status "Backend image built and pushed: $DOCKER_USERNAME/harness-demo:backend-latest"
    else
      print_error "Docker buildx failed"
      cd ..
      exit 1
    fi
  else
    # Regular build for Intel/AMD
    if $BUILD_CMD -t "$DOCKER_USERNAME/harness-demo:backend-latest" . --quiet; then
      print_status "Backend image built: $DOCKER_USERNAME/harness-demo:backend-latest"

      # Push backend image separately for Intel/AMD
      print_info "Pushing backend image to Docker Hub..."
      if docker push "$DOCKER_USERNAME/harness-demo:backend-latest" --quiet; then
        print_status "Backend image pushed to Docker Hub"
      else
        print_error "Docker push failed"
        echo ""
        echo "Common causes:"
        echo "  1. Repository doesn't exist - Create 'harness-demo' at https://hub.docker.com/repository/create"
        echo "  2. Authentication failed - Your credentials may be invalid"
        echo "  3. No push access - Check repository permissions"
        echo ""
        echo "To fix:"
        echo "  • Go to https://hub.docker.com/repository/create"
        echo "  • Create a repository named: harness-demo"
        echo "  • Make it public or private (your choice)"
        echo "  • Then re-run: ./start-demo.sh"
        echo ""
        cd ..
        exit 1
      fi
    else
      print_error "Docker build failed"
      cd ..
      exit 1
    fi
  fi
  cd ..

  # Build test image for Test Intelligence
  print_info "Building test Docker image for Harness Test Intelligence..."
  cd python-tests
  if [ -n "$PUSH_FLAG" ]; then
    # Use buildx with --push for ARM64
    if $BUILD_CMD -t "$DOCKER_USERNAME/harness-demo:test-latest" $PUSH_FLAG . --quiet; then
      print_status "Test image built and pushed: $DOCKER_USERNAME/harness-demo:test-latest"
    else
      print_error "Test image buildx failed"
      cd ..
      exit 1
    fi
  else
    # Regular build for Intel/AMD
    if $BUILD_CMD -t "$DOCKER_USERNAME/harness-demo:test-latest" . --quiet; then
      print_status "Test image built: $DOCKER_USERNAME/harness-demo:test-latest"

      # Push test image
      print_info "Pushing test image to Docker Hub..."
      if docker push "$DOCKER_USERNAME/harness-demo:test-latest" --quiet; then
        print_status "Test image pushed to Docker Hub"
      else
        print_error "Test image push failed (this is not critical, continuing...)"
      fi
    else
      print_error "Test image build failed (this is not critical, continuing...)"
    fi
  fi
  cd ..

  # Build documentation image
  print_info "Building documentation Docker image..."

  # Copy images into markdown directory for Docker build context
  if [ -d "images" ]; then
    cp -r images markdown/ 2>/dev/null || true
  fi

  # Replace dockerhubaccountid placeholder with actual username in markdown files
  print_info "Personalizing lab documentation with your Docker Hub username..."
  echo ""
  echo "   The lab guides will show '$DOCKER_USERNAME/harness-demo' instead of 'dockerhubaccountid/harness-demo'"
  echo "   This makes the instructions easier to follow with your actual Docker Hub account."
  echo ""
  if command -v sed &> /dev/null; then
    # Create temporary copies with placeholder replaced
    for mdfile in markdown/*.md; do
      if [ -f "$mdfile" ]; then
        # Use different sed syntax for macOS vs Linux
        if [[ "$OSTYPE" == "darwin"* ]]; then
          sed -i '.bak' "s/dockerhubaccountid/$DOCKER_USERNAME/g" "$mdfile"
          rm -f "${mdfile}.bak"
        else
          sed -i "s/dockerhubaccountid/$DOCKER_USERNAME/g" "$mdfile"
        fi
      fi
    done
    print_status "Documentation personalized successfully"
  fi

  cd markdown
  if [ -n "$PUSH_FLAG" ]; then
    # Use buildx with --push for ARM64
    if $BUILD_CMD -t "$DOCKER_USERNAME/harness-demo:docs-latest" $PUSH_FLAG . --quiet; then
      print_status "Documentation image built and pushed: $DOCKER_USERNAME/harness-demo:docs-latest"
    else
      print_error "Documentation buildx failed (this is not critical, continuing...)"
    fi
  else
    # Regular build for Intel/AMD
    if $BUILD_CMD -t "$DOCKER_USERNAME/harness-demo:docs-latest" . --quiet; then
      print_status "Documentation image built: $DOCKER_USERNAME/harness-demo:docs-latest"

      # Push documentation image
      print_info "Pushing documentation image to Docker Hub..."
      if docker push "$DOCKER_USERNAME/harness-demo:docs-latest" --quiet; then
        print_status "Documentation image pushed to Docker Hub"
      else
        print_error "Documentation push failed (this is not critical, continuing...)"
      fi
    else
      print_error "Documentation Docker build failed (this is not critical, continuing...)"
    fi
  fi
  cd ..

  # Restore original markdown files (undo personalization to keep git clean)
  print_info "Restoring original documentation files..."
  if command -v git &> /dev/null && git rev-parse --git-dir > /dev/null 2>&1; then
    # Use git to restore original files
    git checkout -- markdown/*.md 2>/dev/null || true
  else
    # Fallback: manually restore using sed
    for mdfile in markdown/*.md; do
      if [ -f "$mdfile" ]; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
          sed -i '.bak' "s/$DOCKER_USERNAME/dockerhubaccountid/g" "$mdfile"
          rm -f "${mdfile}.bak"
        else
          sed -i "s/$DOCKER_USERNAME/dockerhubaccountid/g" "$mdfile"
        fi
      fi
    done
  fi

  # Now create/update Docker Hub secret with authenticated credentials
  print_section "Updating Docker Hub Secret for Image Pulls"

  if [ -n "$DOCKER_USERNAME" ] && [ -n "$DOCKER_LOGIN_PASSWORD" ]; then
    print_info "Creating/updating Docker Hub pull secret with authenticated credentials..."

    # Create secret in default namespace
    if kubectl get secret dockerhub-pull -n default &> /dev/null; then
      kubectl delete secret dockerhub-pull -n default &> /dev/null
    fi

    kubectl create secret docker-registry dockerhub-pull \
      --docker-server=https://index.docker.io/v1/ \
      --docker-username="$DOCKER_USERNAME" \
      --docker-password="$DOCKER_LOGIN_PASSWORD" \
      --docker-email="${DOCKER_USERNAME}@example.com" \
      -n default &> /dev/null

    if [ $? -eq 0 ]; then
      print_status "Docker Hub secret created/updated in default namespace"
    else
      print_error "Failed to create Docker Hub secret in default namespace"
    fi

    # Create secret in harness-delegate-ng namespace (if it exists)
    if kubectl get namespace harness-delegate-ng &> /dev/null; then
      if kubectl get secret dockerhub-pull -n harness-delegate-ng &> /dev/null; then
        kubectl delete secret dockerhub-pull -n harness-delegate-ng &> /dev/null
      fi

      kubectl create secret docker-registry dockerhub-pull \
        --docker-server=https://index.docker.io/v1/ \
        --docker-username="$DOCKER_USERNAME" \
        --docker-password="$DOCKER_LOGIN_PASSWORD" \
        --docker-email="${DOCKER_USERNAME}@example.com" \
        -n harness-delegate-ng &> /dev/null

      if [ $? -eq 0 ]; then
        print_status "Docker Hub secret created/updated in harness-delegate-ng namespace"

        # Attach secret to default service account
        kubectl patch serviceaccount default -n harness-delegate-ng -p '{"imagePullSecrets": [{"name": "dockerhub-pull"}]}' &> /dev/null
        print_status "Attached secret to service account in harness-delegate-ng"
      else
        print_error "Failed to create Docker Hub secret in harness-delegate-ng namespace"
      fi
    fi

    # Attach secret to default service account in default namespace
    kubectl patch serviceaccount default -n default -p '{"imagePullSecrets": [{"name": "dockerhub-pull"}]}' &> /dev/null
    print_status "Attached secret to service account in default namespace"
  fi
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
  DOCKER_PAT=""

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
    DOCKER_PAT=$(grep "DOCKER_PAT=" "$CONFIG_FILE" | cut -d'=' -f2)
  fi

  # If still not found, use a placeholder (should have been saved during Docker build section)
  if [ -z "$DOCKER_PAT" ]; then
    # Check if we're logged in to Docker Hub (might have been logged in via Docker Desktop on first run)
    LOGGED_IN_USER=$(docker info 2>/dev/null | grep "Username:" | awk '{print $2}')
    if [ -n "$LOGGED_IN_USER" ]; then
      print_status "Using Docker Hub session (logged in via Docker Desktop)"
      DOCKER_PAT="logged-in-via-docker-desktop"
    else
      # This shouldn't happen if the Docker build section ran, but handle it anyway
      print_info "Docker Hub password not found in cache"
      echo ""
      echo "Enter your Docker Hub password or Personal Access Token (PAT)"
      echo "To create a PAT: https://hub.docker.com/settings/security"
      echo ""
      read -sp "Docker Hub password/PAT: " DOCKER_PAT
      echo ""

      while [ -z "$DOCKER_PAT" ]; do
        print_error "Password/PAT cannot be empty"
        read -sp "Docker Hub password/PAT: " DOCKER_PAT
        echo ""
      done
    fi
  else
    print_status "Using cached Docker Hub password/PAT for Terraform"
  fi

  # Save configuration for future runs
  {
    echo "DOCKER_USERNAME=$DOCKER_USERNAME"
    echo "HARNESS_ACCOUNT_ID=$HARNESS_ACCOUNT_ID"
    echo "HARNESS_PAT=$HARNESS_PAT"
    echo "DOCKER_PAT=$DOCKER_PAT"
  } > "$CONFIG_FILE"
  print_status "Saved credentials to $CONFIG_FILE for future runs"
  echo ""

  # Update se-parms.tfvars
  print_info "Updating kit/se-parms.tfvars..."
  cat > kit/se-parms.tfvars <<EOF
account_id = "$HARNESS_ACCOUNT_ID"

docker_username = "$DOCKER_USERNAME"
DOCKER_PAT = "$DOCKER_PAT"
EOF
  print_status "Updated se-parms.tfvars with your configuration"

  # Check if Terraform has already been applied
  if [ -f "kit/terraform.tfstate" ] && [ -s "kit/terraform.tfstate" ]; then
    echo ""
    print_status "IaC state already exists - Harness resources appear to be configured"
    print_info "To reconfigure, delete kit/terraform.tfstate or run: cd kit && terraform destroy"
    echo ""
  else

    # Check for Terraform
    print_section "Checking for Terraform"

    if ! command -v terraform &> /dev/null; then
      print_error "Terraform is not installed"
      echo ""
      echo "This demo requires Terraform to provision Harness resources."
      echo ""
      echo "Installation options:"
      echo ""
      echo "Visit: https://www.terraform.io/downloads"
      echo ""
      cd ..
      exit 1
    fi

    print_status "Found Terraform: $(terraform version | head -n1)"

    # Run Terraform
    print_section "Running Terraform"

    cd kit

    # Initialize
    print_info "Running terraform init..."
    if terraform init &> /dev/null; then
      print_status "Terraform initialized"
    else
      print_error "Terraform init failed"
      cd ..
      exit 1
    fi

    # Plan
    print_info "Running terraform plan (this may take 1-2 minutes)..."
    if terraform plan -var="pat=$HARNESS_PAT" -var-file="se-parms.tfvars" -out=plan.tfplan &> /dev/null; then
      print_status "Terraform plan created"
    else
      print_error "Terraform plan failed. Run manually to see errors: cd kit && terraform plan -var=\"pat=$HARNESS_PAT\" -var-file=\"se-parms.tfvars\""
      cd ..
      exit 1
    fi

    # Apply
    print_info "Running terraform apply (this may take 3-5 minutes)..."
    if terraform apply -auto-approve plan.tfplan; then
      print_status "Terraform apply completed - Harness resources created!"
    else
      print_error "Terraform apply failed"
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

# Deploy documentation to Kubernetes
if [ "$SKIP_DOCKER_BUILD" = false ]; then
  print_section "Deploying Documentation"

  # Update docs deployment with Docker Hub username
  print_info "Configuring documentation deployment..."
  sed -i.bak "s/dockerhubaccountid/$DOCKER_USERNAME/g" harness-deploy/docs/docs-deployment.yaml
  rm harness-deploy/docs/docs-deployment.yaml.bak 2>/dev/null

  # Deploy docs to K8s
  print_info "Deploying documentation to Kubernetes..."
  if kubectl apply -f harness-deploy/docs/docs-deployment.yaml > /dev/null 2>&1; then
    print_status "Documentation deployed successfully"
    echo ""
    echo "📚 Documentation available at:"
    echo "   http://localhost:30001"
    echo ""
  else
    print_error "Documentation deployment failed (non-critical)"
  fi

  # Restore original docs deployment file (undo personalization to keep git clean)
  print_info "Restoring original deployment file..."
  if command -v git &> /dev/null && git rev-parse --git-dir > /dev/null 2>&1; then
    git checkout -- harness-deploy/docs/docs-deployment.yaml 2>/dev/null || true
  else
    # Fallback: manually restore using sed
    sed -i.bak "s/$DOCKER_USERNAME/dockerhubaccountid/g" harness-deploy/docs/docs-deployment.yaml
    rm harness-deploy/docs/docs-deployment.yaml.bak 2>/dev/null
  fi
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
  echo "  1. Open the documentation in your browser:"
  echo "     http://localhost:30001"
  echo ""
  echo "  2. Navigate to Harness UI: https://app.harness.io"
  echo "  3. Select the 'Base Demo' project"
  echo "  4. Configure Harness Code Repository:"
  echo "     - Go to Code Repository module"
  echo "     - Click 'partner_demo_kit' repository"
  echo "     - Click 'Clone' > '+Generate Clone Credential'"
  echo "     - Save the username and token"
  echo "     - Enable Secret Scanning: Manage Repository > Security"
  echo "  5. Follow the lab guides at http://localhost:30001"
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
