# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a Harness.io Partner Demo Kit - a self-contained demonstration environment for showcasing Harness platform capabilities (CI/CD, Code Repository, Continuous Verification, Security Testing). The demo runs entirely on local infrastructure (Colima for Apple Silicon, minikube/Docker Desktop/Rancher Desktop for other platforms) to minimize external dependencies.

**Important**: All Harness resources are created in a project called "Base Demo". This segregates demo resources from production environments.

## Architecture

The repository contains three main components that work together:

### Frontend Application
- **Location**: [frontend-app/harness-webapp/](frontend-app/harness-webapp/)
- **Stack**: Angular 17, TypeScript
- **Purpose**: Demo web application with distribution testing UI and feature flag integration
- **Key dependencies**: Harness Feature Flags SDK (`@harnessio/ff-javascript-client-sdk`), ngx-charts for visualization

### Backend Application
- **Location**: [backend/](backend/)
- **Stack**: Django 5.0, Python, PostgreSQL
- **Purpose**: REST API backend serving the demo application
- **Structure**: Standard Django project with `backend/` (core) and `deploy/` (app) modules

### Infrastructure & Deployment
- **Terraform configs**: [kit/](kit/) - Provisions Harness resources (connectors, environments, services, monitored services)
- **K8s manifests**: [harness-deploy/](harness-deploy/) - Deployment and service definitions for frontend and backend
- **Monitoring**: Prometheus configuration at [kit/prometheus.yml](kit/prometheus.yml)

## Build and Development Commands

### Frontend (Angular)
```bash
cd frontend-app/harness-webapp
npm install
npm run build          # Production build
npm run start          # Dev server
npm run test           # Run tests
```

### Backend (Django)
```bash
cd backend
pip install -r requirements.txt
python manage.py migrate
python manage.py runserver
```

### Python Tests
The [python-tests/](python-tests/) directory contains test suites used in the CI/CD demo:
```bash
cd python-tests
pytest                 # Run all tests
```

### Docker Images
The repository uses three Docker images. Replace `dockerhubaccountid` with your Docker Hub account:

**✅ Automated**: The [start-demo.sh](start-demo.sh) script automatically detects your architecture and builds backend and test images with correct platform settings. Manual builds are only needed if:
- Running the script with `--skip-docker-build`
- Rebuilding images after code changes
- Building the frontend image locally

**⚠️ Apple Silicon Users**: When building manually, you must use `--platform linux/amd64` because Harness Cloud runs on amd64 architecture.

**Backend Application** (Django runtime):
```bash
cd backend
# Intel/AMD: docker build -t dockerhubaccountid/harness-demo:backend-latest .
# Apple Silicon:
docker buildx build --platform linux/amd64 -t dockerhubaccountid/harness-demo:backend-latest --push .
```

**Test Image** (CI pipeline with pytest pre-installed):
```bash
cd python-tests
# Intel/AMD: docker build -t dockerhubaccountid/harness-demo:test-latest . && docker push dockerhubaccountid/harness-demo:test-latest
# Apple Silicon:
docker buildx build --platform linux/amd64 -t dockerhubaccountid/harness-demo:test-latest --push .
```

**Frontend Application** (Angular - built in CI, not locally):
```bash
cd frontend-app/harness-webapp
# Only needed if building locally for testing
docker buildx build --platform linux/amd64 -t dockerhubaccountid/harness-demo:demo-base-<tag> --push .
```

**Image Tag Reference:**
- `backend-latest` - Django backend application (production)
- `test-latest` - Python + pytest environment (CI only)
- `demo-base-<tag>` - Frontend Angular application

**Architecture Note**: All images must be amd64 for Harness Cloud compatibility. The start-demo.sh script handles this automatically. Manual builds on Apple Silicon require `docker buildx build --platform linux/amd64`.

## Infrastructure Commands

### Automated Setup (Recommended)

The repository includes automation scripts for complete demo setup:

**start-demo.sh** - Automated infrastructure and Harness resource setup:
```bash
# Make executable (first time only)
chmod +x start-demo.sh stop-demo.sh

# Run complete setup
./start-demo.sh

# Options:
./start-demo.sh --skip-docker-build   # Skip backend image build
./start-demo.sh --skip-terraform      # Skip Harness resource creation
```

**What start-demo.sh automates:**
1. **Detects platform** (macOS/Windows/Linux) and architecture (ARM64/AMD64)
2. **Validates Kubernetes tool** based on platform:
   - Apple Silicon Macs: Requires Colima with AMD64 emulation (Rosetta 2)
   - Windows: Recommends minikube (allows Docker Desktop/Rancher Desktop)
   - Other platforms: Flexible (minikube, Colima, Docker Desktop, Rancher Desktop)
3. Checks prerequisites (Docker, kubectl, Terraform)
4. Detects and starts Kubernetes (Colima/minikube) if needed
5. **Verifies cluster architecture** (ensures AMD64 for Apple Silicon compatibility with Harness Cloud)
6. **Creates Docker Hub secret** (`dockerhub-pull`) in Kubernetes for pulling Harness CI images
7. Deploys Prometheus for continuous verification
8. Authenticates to Docker Hub (smart detection of existing login)
9. **Detects architecture** (Intel/AMD vs Apple Silicon) and builds Docker images with correct platform:
   - Backend image (backend-latest)
   - Test image (test-latest)
   - Documentation image (docs-latest)
7. **Updates Docker Hub secret** with authenticated credentials after login
8. **Collects Harness credentials** (Account ID, PAT, Docker password)
9. **Updates kit/se-parms.tfvars** automatically
10. **Runs Terraform** (init, plan, apply) to create all Harness resources
11. Saves configuration to `.demo-config` for subsequent runs
12. Deploys documentation to Kubernetes at http://localhost:30001

**stop-demo.sh** - Interactive cleanup script with smart defaults:
```bash
./stop-demo.sh                    # Shows interactive menu (default: minimal cleanup)

# Interactive menu options:
# 1) Stop K8s deployments only (Recommended - preserves Harness resources)
# 2) Stop K8s deployments + Delete Prometheus
# 3) Stop K8s deployments + Stop cluster
# 4) Full cleanup (delete all Harness resources)
# 5) Complete cleanup (everything including cluster)
# 6) Custom cleanup options
# 0) Exit without doing anything

# Command-line flags (skip interactive menu):
./stop-demo.sh --delete-prometheus      # Also remove Prometheus
./stop-demo.sh --stop-cluster           # Also stop Colima/minikube
./stop-demo.sh --delete-harness-project # Delete Harness 'Base Demo' project
./stop-demo.sh --delete-docker-repo     # Delete Docker Hub repository
./stop-demo.sh --full-cleanup           # Complete cleanup (keeps credentials)
./stop-demo.sh --no-interactive         # Skip menu, use minimal cleanup
```

**Recommended Workflow:**
- After running the demo, use the default interactive menu (option 1) to stop deployments
- Preserves Harness resources for easy restart: `./start-demo.sh --skip-terraform`
- Full cleanup only needed when completely resetting the demo environment

**Credential Management:**
- Credentials saved to `.demo-config` (git-ignored)
- Reuses values on subsequent runs
- Supports environment variable `DEMO_BASE_PAT` for Harness PAT
- Detects Docker Desktop login automatically

### Terraform (Harness Resource Provisioning) - Manual Method

**Important**: Set the Harness PAT as an environment variable on Mac/Linux:
```bash
cd kit

# Export the PAT (required for Mac/Linux)
export DEMO_BASE_PAT="pat.SAn9tg9eRrWyEJyLZ01ibw.xx"

# Verify it's set correctly
echo $DEMO_BASE_PAT

# Run Terraform commands
terraform init
terraform plan -var="pat=$DEMO_BASE_PAT" -var-file="se-parms.tfvars" -out=plan.tfplan
terraform apply -auto-approve plan.tfplan
```

The IaC configuration creates a "Base Demo" project with:
- Harness project "Base Demo"
- K8s connector (`workshop_k8s`) - for local Kubernetes cluster (Colima/minikube/Rancher Desktop/Docker Desktop)
- Docker connector (`workshopdocker`) - for Docker Hub
- Prometheus connector - for continuous verification
- Docker username/password secrets
- "Compile Application" template
- Dev and Prod environments
- K8s Dev infrastructure definition
- Backend service (with K8s manifests from Harness Code Repository)
- Monitored services (backend_dev, backend_prod) for continuous verification
- Code repository (`partner_demo_kit`) mirrored from GitHub

### Kubernetes (Platform-Specific Setup)

**Apple Silicon (M1/M2/M3/M4) - Colima with Rosetta 2 (REQUIRED):**
```bash
# Install Colima and all required dependencies
brew install colima docker kubectl qemu lima-additional-guestagents

# If you have an existing Colima instance, delete it first (recommended for clean setup)
colima stop
colima delete

# Start Colima with AMD64 emulation via Rosetta 2
colima start --vm-type=vz --vz-rosetta --arch x86_64 --cpu 4 --memory 8 --kubernetes

# Note: First startup takes 5-10 minutes while downloading images

# Verify AMD64 architecture (should show "amd64")
kubectl get nodes -o jsonpath='{.items[0].status.nodeInfo.architecture}'

# Check Colima status
colima status  # Should show "arch: x86_64"

# Setup Prometheus (from kit/ directory)
cd kit
kubectl create namespace monitoring
kubectl -n monitoring apply -f ./prometheus.yml

# View deployments
kubectl get pods -A | grep deployment
kubectl get services -A | grep svc

# Cleanup
kubectl delete deployment frontend-deployment backend-deployment
kubectl delete service web-frontend-svc web-backend-svc

# Stop Colima
colima stop
```

**Windows - Minikube (Recommended):**
```bash
# Download from: https://minikube.sigs.k8s.io/docs/start/

# Start minikube and enable addons
minikube start
minikube addons enable metrics-server

# Setup Prometheus (from kit/ directory)
cd kit
kubectl create namespace monitoring
kubectl -n monitoring apply -f ./prometheus.yml

# View deployments
kubectl get pods -A | grep deployment
kubectl get services -A | grep svc

# Access services (requires minikube tunnel running in separate terminal)
minikube tunnel

# Cleanup
kubectl delete deployment frontend-deployment backend-deployment
kubectl delete service web-frontend-svc web-backend-svc
```

**Intel Mac / Linux - Flexible Options:**
```bash
# Option 1: Minikube
minikube start
minikube addons enable metrics-server

# Option 2: Colima (no need for architecture emulation)
colima start --cpu 4 --memory 8 --kubernetes

# Option 3: Rancher Desktop - Enable Kubernetes in preferences
# Option 4: Docker Desktop - Enable Kubernetes in settings

# Prometheus setup (same for all)
cd kit
kubectl create namespace monitoring
kubectl -n monitoring apply -f ./prometheus.yml

# Services automatically accessible with Rancher/Docker Desktop (no tunnel needed)
# For minikube: Run 'minikube tunnel' in a separate terminal
```

### Prometheus with ngrok (Optional)

If the Harness delegate cannot reach the cluster-local Prometheus URL, expose it via ngrok:

```bash
# Port forward Prometheus
kubectl port-forward -n monitoring svc/prometheus-k8s 9090:9090

# In another terminal, expose via ngrok
ngrok http 9090

# Copy the ngrok HTTPS URL (e.g., https://abc123.ngrok.io)
# Update the Prometheus connector URL in Harness UI or kit/main.tf to use this ngrok URL
```

## Important Configuration Details

### Docker Hub Account ID Replacement
Throughout the codebase, replace the placeholder `dockerhubaccountid` with your actual Docker Hub account ID. This appears in:
- [kit/main.tf](kit/main.tf) - Line 300: `imagePath: dockerhubaccountid/harness-demo`
- Build commands in documentation
- Demo instructions

### IaC Variables
Configure [kit/se-parms.tfvars](kit/se-parms.tfvars) with:
- `account_id`: Your Harness account ID (found in URL when viewing your profile)
- `docker_username`: Docker Hub username
- `DOCKER_PAT`: Docker Hub password/PAT

### Environment Setup Requirements
- Docker and Docker Hub account with `harness-demo` repository created
- **Kubernetes** (platform-specific):
  - **Apple Silicon Macs**: Colima with Rosetta 2 for AMD64 emulation (REQUIRED)
  - **Windows**: minikube (recommended), Docker Desktop, or Rancher Desktop
  - **Intel Mac/Linux**: minikube, Colima, Docker Desktop, or Rancher Desktop
- **Terraform** - IaC tool for provisioning Harness resources
- kubectl and helm
- Harness account with CD, CI, and Code Repo modules enabled
- Harness delegate installed at account level using Helm

### Harness Code Repository Git Credentials

After Terraform creates the `partner_demo_kit` repository in Harness Code:

1. Navigate to Harness UI > Code Repository module > "Base Demo" project
2. Click on "partner_demo_kit" repository
3. Click "Clone" button (top right) > "+Generate Clone Credential"
4. Save the generated username and token
5. Use these credentials when cloning or pushing to the Harness Code Repository

The repository is initially mirrored from `harness-community/partner-demo-kit` on GitHub.

### Repository Clone Location

When cloning this repository locally for development:
- Recommended locations: `~/projects/partner-demo-kit` or `~/Documents/partner-demo-kit`
- Keep it accessible for easy navigation during demos

## Demo Flow

The complete demo workflow is documented in:
1. [base-resources.txt](base-resources.txt) - Initial setup and resource provisioning
2. [base-demo.txt](base-demo.txt) - Step-by-step demo execution guide (all in "Base Demo" project)
3. [markdown/](markdown/) - Individual demo module guides (0-7) - originally for Instruqt workshops

The demo demonstrates (all within "Base Demo" project):
1. **Code Repository Secret Scanning** - Demonstrates blocking sensitive commits (TOKEN in backend/entrypoint.sh)
2. **CI Pipeline** - Build stage with test intelligence, compile template, and Docker image push (uses **Harness Cloud** infrastructure)
3. **Frontend Deployment** - Rolling deployment strategy to local K8s
4. **Backend Deployment** - Canary deployment strategy to local K8s
5. **Continuous Verification** - Uses Prometheus metrics to verify canary deployments (5-minute duration)
6. **Security Scanning** - Requires licensed partner org (not available in free tier)
7. **OPA Policy Enforcement** - Requires licensed partner org (not available in free tier)

## Infrastructure Architecture

- **CI Builds**: Use Harness Cloud (requires credit card verification, works on all platforms)
- **CD Deployments**: Use local Kubernetes cluster
  - Apple Silicon: Colima with AMD64 emulation (Rosetta 2)
  - Other platforms: minikube, Docker Desktop, or Rancher Desktop

## Reset/Cleanup Procedure

To reset the demo environment and start fresh:

**1. Harness Resources (in "Base Demo" project):**
```
- Navigate to Harness UI > Code Repo module > Manage Repository
  - Delete "partner_demo_kit" repository
- Navigate to Harness UI > Projects
  - Delete "Base Demo" project (this removes all project resources)
```

**2. Local IaC State:**
```bash
cd kit
git clean -dxf  # WARNING: Removes all untracked files including .tfstate files

# OR manually destroy with Terraform first:
terraform destroy -var="pat=$DEMO_BASE_PAT" -var-file="se-parms.tfvars"
```

**3. Docker Hub:**
```
- Remove repository "dockerhubaccountid/harness-demo" from Docker Hub UI
```

**4. Kubernetes Resources:**
```bash
kubectl delete deployment frontend-deployment
kubectl delete service web-frontend-svc
kubectl delete deployment backend-deployment
kubectl delete service web-backend-svc
```

## Key Files for Customization

- Frontend Docker image tag pattern: `demo-base-<+pipeline.sequenceId>`
- Backend deployment includes canary verification with 5-minute duration
- The "canary" feature: A yellow cartoon graphic served by canary pods (visible in distribution test UI at localhost:8080)
- Prometheus metrics drive the continuous verification step in the backend deployment
- Architecture selection for Harness Cloud builds: Choose arm64 for Apple Silicon (M1/M2/M3) or amd64 for Intel

## Changes from Instruqt Version

This repository was originally created for Instruqt-based workshops. Key differences for local/partner use:

- **Removed**: Instruqt-specific connector named `instruqt_k8` → Renamed to `workshop_k8s` for local K8s
- **Removed**: Instruqt sandbox URLs in compile template → Changed to `http://localhost:8000`
- **Removed**: Instruqt variable references like `<+variable.sandbox_id>` → Simplified for local use
- **Added**: Platform-specific Kubernetes requirements (Colima for Apple Silicon, minikube for Windows)
- **Added**: OS and architecture detection in start-demo.sh
- **Added**: Automatic AMD64 architecture verification for Apple Silicon
- **Added**: Instructions for Mac/Linux PAT export
- **Added**: ngrok option for exposing Prometheus
- **Added**: Git credential setup for Harness Code Repository
- **Added**: Colima as primary option for macOS (especially Apple Silicon)
- **Added**: Rancher Desktop and Docker Desktop as alternatives
- **Clarified**: All resources go into "Base Demo" project for proper segregation
