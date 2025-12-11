# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a Harness.io Partner Demo Kit - a self-contained demonstration environment for showcasing Harness platform capabilities (CI/CD, Code Repository, Continuous Verification, Security Testing). The demo runs entirely on local infrastructure (minikube or Rancher Desktop) to minimize external dependencies.

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
- **OpenTofu/Terraform configs**: [kit/](kit/) - Provisions Harness resources (connectors, environments, services, monitored services)
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
Both applications are containerized. Replace `dockerhubaccountid` with your Docker Hub account:

**Backend**:
```bash
cd backend
docker build -t dockerhubaccountid/harness-demo:backend-latest .
docker push dockerhubaccountid/harness-demo:backend-latest
```

**Frontend**:
```bash
cd frontend-app/harness-webapp
docker build -t dockerhubaccountid/harness-demo:demo-base-<tag> .
docker push dockerhubaccountid/harness-demo:demo-base-<tag>
```

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
1. Checks prerequisites (Docker, kubectl, OpenTofu/Terraform)
2. Auto-detects OpenTofu or Terraform (prefers Terraform if already installed for backward compatibility)
3. Offers to install OpenTofu if neither tool is found (macOS with Homebrew)
4. Detects and starts Kubernetes (minikube/Rancher Desktop)
5. Deploys Prometheus for continuous verification
6. Authenticates to Docker Hub (smart detection of existing login)
7. Builds and pushes backend Docker image
8. **Collects Harness credentials** (Account ID, PAT, Docker password)
9. **Updates kit/se-parms.tfvars** automatically
10. **Runs OpenTofu/Terraform** (init, plan, apply) to create all Harness resources
11. Saves configuration to `.demo-config` for subsequent runs

**stop-demo.sh** - Cleanup script:
```bash
./stop-demo.sh                    # Remove deployed applications
./stop-demo.sh --delete-prometheus # Also remove Prometheus
./stop-demo.sh --stop-cluster     # Also stop minikube
./stop-demo.sh --full-cleanup     # Complete cleanup
```

**Credential Management:**
- Credentials saved to `.demo-config` (git-ignored)
- Reuses values on subsequent runs
- Supports environment variable `DEMO_BASE_PAT` for Harness PAT
- Detects Docker Desktop login automatically

### OpenTofu/Terraform (Harness Resource Provisioning) - Manual Method

**Important**: Set the Harness PAT as an environment variable on Mac/Linux:
```bash
cd kit

# Export the PAT (required for Mac/Linux)
export DEMO_BASE_PAT="pat.SAn9tg9eRrWyEJyLZ01ibw.xx"

# Verify it's set correctly
echo $DEMO_BASE_PAT

# Using OpenTofu (recommended)
tofu init
tofu plan -var="pat=$DEMO_BASE_PAT" -var-file="se-parms.tfvars" -out=plan.tfplan
tofu apply -auto-approve plan.tfplan

# OR using Terraform (backward compatibility)
terraform init
terraform plan -var="pat=$DEMO_BASE_PAT" -var-file="se-parms.tfvars" -out=plan.tfplan
terraform apply -auto-approve plan.tfplan
```

The IaC configuration creates a "Base Demo" project with:
- Harness project "Base Demo"
- K8s connector (`workshop_k8s`) - for local minikube/Rancher Desktop cluster
- Docker connector (`workshopdocker`) - for Docker Hub
- Prometheus connector - for continuous verification
- Docker username/password secrets
- "Compile Application" template
- Dev and Prod environments
- K8s Dev infrastructure definition
- Backend service (with K8s manifests from Harness Code Repository)
- Monitored services (backend_dev, backend_prod) for continuous verification
- Code repository (`partner_demo_kit`) mirrored from GitHub

### Kubernetes (Minikube or Rancher Desktop)

**With Minikube:**
```bash
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
kubectl delete deployment frontend-deployment
kubectl delete service web-frontend-svc
kubectl delete deployment backend-deployment
kubectl delete service web-backend-svc
```

**With Rancher Desktop:**
```bash
# Rancher Desktop provides a built-in Kubernetes cluster
# Enable Kubernetes in Rancher Desktop preferences

# Setup Prometheus (from kit/ directory)
cd kit
kubectl create namespace monitoring
kubectl -n monitoring apply -f ./prometheus.yml

# View deployments
kubectl get pods -A | grep deployment
kubectl get services -A | grep svc

# Services are automatically accessible (no tunnel needed)
# Access application at: http://localhost:8080

# Cleanup
kubectl delete deployment frontend-deployment
kubectl delete service web-frontend-svc
kubectl delete deployment backend-deployment
kubectl delete service web-backend-svc
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
- `docker_password`: Docker Hub password/PAT

### Environment Setup Requirements
- Docker and Docker Hub account with `harness-demo` repository created
- **Kubernetes**: Either minikube with metrics-server addon OR Rancher Desktop
- **OpenTofu** (recommended) or Terraform - IaC tool for provisioning Harness resources
- kubectl and helm
- Harness account with CD, CI, and Code Repo modules enabled
- Harness delegate installed at account level using Helm

### Harness Code Repository Git Credentials

After OpenTofu/Terraform creates the `partner_demo_kit` repository in Harness Code:

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
2. **CI Pipeline** - Build stage with test intelligence, compile template, and Docker image push
3. **Frontend Deployment** - Rolling deployment strategy to local K8s
4. **Backend Deployment** - Canary deployment strategy to local K8s
5. **Continuous Verification** - Uses Prometheus metrics to verify canary deployments (5-minute duration)
6. **Security Scanning** - Requires licensed partner org (not available in free tier)
7. **OPA Policy Enforcement** - Requires licensed partner org (not available in free tier)

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

# OR manually destroy with OpenTofu/Terraform first:
tofu destroy -var="pat=$DEMO_BASE_PAT" -var-file="se-parms.tfvars"
# OR: terraform destroy -var="pat=$DEMO_BASE_PAT" -var-file="se-parms.tfvars"
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
- **Added**: Instructions for Mac/Linux PAT export
- **Added**: ngrok option for exposing Prometheus
- **Added**: Git credential setup for Harness Code Repository
- **Added**: Rancher Desktop as alternative to minikube
- **Clarified**: All resources go into "Base Demo" project for proper segregation
