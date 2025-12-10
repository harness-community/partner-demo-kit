# Harness.io Partner Demo Kit

## Overview
This repository contains everything needed to deliver compelling Harness.io demonstrations using local resources. Built from our Unscripted workshop materials, this kit enables partners to quickly set up and customize Harness.io demos without requiring complex cloud infrastructure or specialized environments.

All demo resources are created in a Harness project called **"Base Demo"** to keep demo activities segregated from production environments.

## Key Benefits
- **Minimal Prerequisites**: Runs on standard developer workstation using common tools
- **Self-Contained**: All necessary components included (Terraform configs, sample application code)
- **Customizable**: Use as a foundation for building customer-specific demonstrations
- **Field-Tested**: Based on materials from Harness Unscripted workshops
- **Project Segregation**: All resources created in dedicated "Base Demo" project

## What This Demo Showcases

1. **Code Repository Secret Scanning** - Block sensitive data from being committed
2. **CI Pipeline with Test Intelligence** - Automated testing and Docker image builds
3. **Continuous Deployment** - Rolling and canary deployment strategies
4. **Continuous Verification** - Automated deployment validation using Prometheus metrics
5. **Security Testing** - Available with licensed partner organization
6. **Policy Enforcement (OPA)** - Available with licensed partner organization

## Prerequisites

### Required Tools
- **Git**: Version control
- **Docker**: Container runtime ([Docker Desktop](https://www.docker.com/products/docker-desktop) or Docker Engine)
- **Kubernetes**: Choose one:
  - [Rancher Desktop](https://rancherdesktop.io/) (Recommended - easier setup, no tunnel needed)
  - [minikube](https://minikube.sigs.k8s.io/docs/start/) (Requires `minikube tunnel` for service access)
- **kubectl**: Kubernetes CLI (usually included with Rancher Desktop/minikube)
- **Helm**: Kubernetes package manager
- **Terraform**: Infrastructure as Code tool (v1.0+)
- **Node.js & npm**: For frontend application (Node 20+)
- **Python**: For backend application (Python 3.8+)

### Required Accounts
- **Harness Account**: Sign up at [app.harness.io](https://app.harness.io)
  - Enable modules: CI (Continuous Integration), CD (Continuous Delivery), Code Repository
- **Docker Hub Account**: Sign up at [hub.docker.com](https://hub.docker.com)
  - Create a repository named `harness-demo`
  - Generate a Personal Access Token (Settings > Security > Personal Access Tokens)

### System Requirements
- **CPU**: 4+ cores recommended
- **RAM**: 8GB minimum, 16GB recommended
- **Disk**: 20GB free space
- **OS**: macOS, Linux, or Windows with WSL2

## Quick Start Guide

### Step 1: Clone the Repository

```bash
# Clone this repository
git clone https://github.com/harness-community/partner-demo-kit.git
cd partner-demo-kit
```

**Recommended Location**: Save in an easily accessible location like:
- `~/projects/partner-demo-kit`
- `~/Documents/partner-demo-kit`

### Step 2: Set Up Kubernetes

**Option A: Rancher Desktop (Recommended)**
1. Download and install [Rancher Desktop](https://rancherdesktop.io/)
2. Open Rancher Desktop preferences
3. Enable Kubernetes
4. Wait for Kubernetes to start (green indicator)
5. Services will be automatically accessible at `localhost`

**Option B: minikube**
```bash
# Start minikube
minikube start

# Enable metrics-server addon
minikube addons enable metrics-server

# In a separate terminal, run minikube tunnel (required for service access)
# Keep this running during the demo
minikube tunnel
```

### Step 3: Deploy Prometheus (for Continuous Verification)

```bash
# Navigate to the kit directory
cd kit

# Create monitoring namespace
kubectl create namespace monitoring

# Deploy Prometheus
kubectl -n monitoring apply -f ./prometheus.yml

# Verify Prometheus is running
kubectl get pods -n monitoring
```

**Optional - Expose Prometheus with ngrok** (if Harness delegate can't reach cluster-local URL):
```bash
# Port forward Prometheus
kubectl port-forward -n monitoring svc/prometheus-k8s 9090:9090

# In another terminal, expose via ngrok
ngrok http 9090
# Copy the HTTPS URL (e.g., https://abc123.ngrok.io)
# You'll use this URL in the Terraform configuration later
```

### Step 4: Build and Push Backend Docker Image

```bash
# Navigate to backend directory
cd ../backend

# Build the Docker image
# Replace "dockerhubaccountid" with YOUR Docker Hub username
docker build -t dockerhubaccountid/harness-demo:backend-latest .

# Login to Docker Hub
docker login -u dockerhubaccountid

# Push the image
docker push dockerhubaccountid/harness-demo:backend-latest
```

**Important**: Remember to replace `dockerhubaccountid` throughout the repository with your actual Docker Hub username.

### Step 5: Configure Harness Account

1. **Log in to Harness**: [app.harness.io](https://app.harness.io)

2. **Enable Required Modules**:
   - Navigate to Account Settings > Subscriptions
   - Enable: **CI**, **CD**, and **Code Repository**

3. **Install Harness Delegate**:
   - Go to Account Settings > Delegates
   - Click "New Delegate"
   - Select "Kubernetes" and follow the Helm installation instructions
   - Example:
     ```bash
     helm repo add harness-delegate https://app.harness.io/storage/harness-download/delegate-helm-chart/
     helm upgrade -i helm-delegate harness-delegate/harness-delegate-ng \
       --namespace harness-delegate-ng --create-namespace \
       --set delegateName=helm-delegate \
       --set accountId=YOUR_ACCOUNT_ID \
       --set delegateToken=YOUR_DELEGATE_TOKEN
     ```

4. **Get Your Harness Account ID**:
   - Click on your profile (top right)
   - Your account ID is in the URL (e.g., `VEuU4vZ6QmSJZcgvnccqYQ`)

5. **Create a Harness API Token**:
   - Go to your profile > My API Keys & Tokens
   - Create a new token with appropriate permissions
   - Save this token securely

### Step 6: Configure Terraform Variables

```bash
# Navigate to kit directory
cd ../kit

# Edit se-parms.tfvars
# Replace the placeholder values with your actual values:
```

**se-parms.tfvars**:
```hcl
account_id = "your-harness-account-id"
docker_username = "your-dockerhub-username"
docker_password = "your-dockerhub-pat"
```

**Important**: Also update `dockerhubaccountid` in [kit/main.tf](kit/main.tf) (line ~300) with your Docker Hub username.

### Step 7: Run Terraform to Create Harness Resources

```bash
# Set your Harness API token as an environment variable (Mac/Linux)
export DEMO_BASE_PAT="pat.your-actual-token-here"

# Verify it's set
echo $DEMO_BASE_PAT

# Initialize Terraform
terraform init

# Preview the changes
terraform plan -var="pat=$DEMO_BASE_PAT" -var-file="se-parms.tfvars" -out=plan.tfplan

# Apply the configuration
terraform apply -auto-approve plan.tfplan
```

**What Terraform Creates** (all in "Base Demo" project):
- Harness project "Base Demo"
- Kubernetes connector (workshop_k8s)
- Docker Hub connector (workshopdocker)
- Prometheus connector
- Docker credentials (secrets)
- "Compile Application" template
- Dev and Prod environments
- K8s Dev infrastructure
- Backend service
- Monitored services for continuous verification
- Code repository (partner_demo_kit) mirrored from GitHub

### Step 8: Configure Harness Code Repository

1. Navigate to Harness UI > **Code Repository** module
2. Select **"Base Demo"** project
3. Click on **"partner_demo_kit"** repository
4. Click **"Clone"** (top right) > **"+Generate Clone Credential"**
5. Save the generated username and token
6. Enable **Secret Scanning**:
   - Go to Manage Repository > Security
   - Turn on "Secret Scanning"
   - Save

### Step 9: Run the Demo

Follow the step-by-step demo guide in [base-demo.txt](base-demo.txt) which walks through:

1. **Secret Scanning Demo**: Try to push a secret and see it blocked
2. **Build Pipeline**: Create CI pipeline with test intelligence
3. **Frontend Deployment**: Deploy frontend with rolling strategy
4. **Backend Deployment**: Deploy backend with canary strategy
5. **Continuous Verification**: Verify deployments using Prometheus metrics

**Access the Demo Application**:
- **Rancher Desktop**: http://localhost:8080 (automatic)
- **minikube**: http://localhost:8080 (requires `minikube tunnel` running)

## Directory Structure

```
.
├── README.md              # Complete setup and demo guide
├── CLAUDE.md              # Instructions for Claude Code AI assistant
├── kit/                   # Terraform Infrastructure as Code
│   ├── main.tf            # Main Terraform configuration
│   ├── se-parms.tfvars    # Your configuration variables
│   └── prometheus.yml     # Prometheus deployment
├── backend/               # Django backend application
│   ├── Dockerfile
│   └── requirements.txt
├── frontend-app/          # Angular frontend application
│   └── harness-webapp/
│       ├── Dockerfile
│       └── package.json
├── harness-deploy/        # Kubernetes manifests
│   ├── backend/           # Backend K8s resources
│   └── frontend/          # Frontend K8s resources
├── python-tests/          # Test suites for CI demo
└── markdown/              # Step-by-step lab guides (0-7)
    ├── 0-login.md         # Getting started and verification
    ├── 1-coderepo.md      # Secret scanning demo
    ├── 2-build.md         # CI pipeline setup
    ├── 3-cd-frontend.md   # Frontend deployment
    ├── 4-cd-backend.md    # Backend canary deployment
    ├── 5-security.md      # Security testing (licensed only)
    ├── 6-cv.md            # Continuous verification
    └── 7-opa.md           # OPA policy enforcement (licensed only)
```

## Troubleshooting

### Common Issues

**Issue**: Terraform fails with authentication error
- **Solution**: Verify `DEMO_BASE_PAT` environment variable is set correctly: `echo $DEMO_BASE_PAT`

**Issue**: Services not accessible at localhost:8080
- **Solution** (minikube): Ensure `minikube tunnel` is running in a separate terminal
- **Solution** (Rancher Desktop): Check that Kubernetes is enabled in preferences

**Issue**: Prometheus connector fails in Harness
- **Solution**: Use ngrok to expose Prometheus and update the connector URL to the ngrok HTTPS URL

**Issue**: Docker image push fails
- **Solution**: Verify you're logged in to Docker Hub: `docker login -u your-username`

**Issue**: Harness delegate not connecting
- **Solution**: Check delegate pod status: `kubectl get pods -n harness-delegate-ng`

### Verifying Your Setup

```bash
# Check Kubernetes is running
kubectl cluster-info

# Check Prometheus is deployed
kubectl get pods -n monitoring

# Check deployments (after running demo)
kubectl get pods -A | grep deployment
kubectl get services -A | grep svc

# Check Harness delegate
kubectl get pods -n harness-delegate-ng
```

## Resetting the Demo

To start fresh and reset everything:

**1. Delete Harness Resources**:
- Navigate to Harness UI > Code Repository > Manage Repository
  - Delete "partner_demo_kit" repository
- Navigate to Projects
  - Delete "Base Demo" project

**2. Clean Local Terraform State**:
```bash
cd kit
git clean -dxf  # WARNING: This removes all untracked files
```

**3. Delete Docker Hub Repository**:
- Go to Docker Hub and delete the "harness-demo" repository

**4. Clean Kubernetes Resources**:
```bash
kubectl delete deployment frontend-deployment
kubectl delete service web-frontend-svc
kubectl delete deployment backend-deployment
kubectl delete service web-backend-svc
```

## Resources & Support

- **Video Walkthrough**: [Watch on YouTube](https://www.youtube.com/watch?v=OgUyeZVYQeg)
- **Detailed Setup Guide**: [base-resources.txt](base-resources.txt)
- **Demo Execution Guide**: [base-demo.txt](base-demo.txt)
- **Harness Documentation**: [docs.harness.io](https://docs.harness.io)

For questions or assistance:
- Contact your Harness Partner Manager
- Submit issues via [GitHub](https://github.com/harness-community/partner-demo-kit/issues)

## Architecture Notes

- **Frontend**: Angular 17 application with Harness Feature Flags integration
- **Backend**: Django 5.0 REST API
- **Local Kubernetes**: Rancher Desktop (recommended) or minikube
- **Monitoring**: Prometheus for continuous verification metrics
- **CI/CD**: Harness Cloud for builds, local K8s for deployments
- **Image Storage**: Docker Hub

## Contributing

We welcome contributions and suggestions to improve this demo kit. Please submit pull requests or open issues for any enhancements.

---

*Note: This demo kit is maintained by Harness.io for partner use. While it's designed to be self-contained, partners are encouraged to customize and extend it based on specific customer needs.*
