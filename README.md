# Harness Partner Demo Kit
## Partner Technical Sales Enablement Training

## Overview
This repository is your complete training environment for mastering Harness demonstrations and sales enablement. Designed for both **potential partners** evaluating Harness partnership opportunities and **current partners** seeking sales engineering enablement training, this kit provides everything needed to deliver compelling Harness.io demonstrations using local resources, without requiring complex cloud infrastructure or specialized environments.

Built from our Unscripted conference workshop materials, this hands-on training culminates in a **customer pitch recording** where you demonstrate your ability to sell Harness to prospective clients.

All demo resources are created in a Harness project called **"Base Demo"** to keep demo activities segregated from production environments.

## Training Objectives

After completing this training, you will be able to:

✅ **Independently execute a complete Harness demonstration**
✅ **Implement a Harness demo environment** with version-controlled sample applications and pipelines
✅ **Construct customer-specific demonstrations** by mapping appropriate Harness features to identified pain points and creating relevant proof-of-concept environments

## Key Training Takeaways
- **Harness Skills**: Hands-on experience with CI/CD, Code Repository, Continuous Verification, and Security Testing
- **Harness Home Lab**: Your own local demonstration environment ready for customer presentations

## Training Path

This training consists of four progressive sections:

1. **[3-Minute Guide to Partner Technical Sales Training](#quick-start-guide)** - Get started quickly with automated setup
2. **[Hands-On Lab: Navigate the {Unscripted} Demo Track](#step-9-run-the-demo)** - Complete the guided demo labs
3. **[Infrastructure Setup: Building Your Harness Home Lab](#manual-setup)** - Deep dive into manual configuration
4. **[Final: Create and Submit Your Custom Demo Recording](#next-steps)** - Demonstrate your mastery

**Next Steps**: After completing the training, you'll have a fully functional Harness demo environment and the skills to customize demonstrations for customer engagements.

---

## Key Benefits
- **Minimal Prerequisites**: Runs on standard developer workstation using common tools
- **Self-Contained**: All necessary components included (Terraform configs, sample application code)
- **Customizable**: Use as a foundation for building customer-specific demonstrations
- **Field-Tested**: Based on materials from Harness Unscripted workshops
- **Project Segregation**: All resources created in dedicated "Base Demo" project

## What This Demo Showcases

1. **Code Repository Secret Scanning** - Block sensitive data from being committed
2. **CI Pipeline with Test Intelligence** - Automated testing and Docker image builds (**Harness Cloud**)
3. **Continuous Deployment** - Rolling and canary deployment strategies (local Kubernetes)
4. **Continuous Verification** - Automated deployment validation using Prometheus metrics
5. **Security Testing** - Available with licensed partner organization
6. **Policy Enforcement (OPA)** - Available with licensed partner organization

## Infrastructure Requirements

- **CI Builds**: Harness Cloud (requires credit card for account verification - free tier available)
- **CD Deployments**: Local Kubernetes (Rancher Desktop or minikube)

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
  - **Important**: Harness Cloud requires credit card verification (free tier available)
  - Add credit card in Account Settings > Billing to enable Harness Cloud for CI builds
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

## Automated Setup (Recommended)

For a faster setup experience, use the provided automation scripts:

### Quick Start with Scripts

```bash
# Make scripts executable (first time only)
chmod +x start-demo.sh stop-demo.sh

# Start all local infrastructure
./start-demo.sh
```

### What the Startup Script Does

The `start-demo.sh` script automates the **complete demo setup** from local infrastructure to Harness resources:

**1. Prerequisites Check**
- Verifies Docker, kubectl, Terraform, and other required tools are installed
- Checks that Docker daemon is running

**2. Kubernetes Detection & Startup**
- Automatically detects your Kubernetes environment (minikube, Rancher Desktop, or other)
- Starts minikube if needed and enables metrics-server addon
- Verifies cluster connectivity

**3. Prometheus Deployment**
- Creates monitoring namespace if it doesn't exist
- Deploys Prometheus for continuous verification metrics
- Waits for Prometheus to be ready

**4. Docker Hub Authentication** (Smart Detection)
- **If already logged in** (via Docker Desktop): Uses existing credentials automatically
- **If not logged in**: Checks for saved username in these locations (in order):
  1. Local `.demo-config` file (from previous runs)
  2. `kit/se-parms.tfvars` (Terraform configuration)
  3. Interactive prompt (if not found)
- Saves your username to `.demo-config` for future runs
- Prompts for login with helpful instructions about using a Personal Access Token (PAT)

**5. Backend Image Build & Push**
- Builds the Django backend Docker image
- Pushes to your Docker Hub repository
- Provides clear error messages if build or push fails

**6. Harness Configuration & IaC Provisioning** (Automated!)
- **Smart credential collection**: Reuses values from previous runs or prompts for:
  - Harness Account ID (from URL when viewing your profile)
  - Harness Personal Access Token (PAT)
  - Docker Hub password/PAT (if not already logged in)
- **Automatic configuration**: Updates `kit/se-parms.tfvars` with your values
- **IaC execution**: Runs Terraform init, plan, and apply automatically
- **Idempotent**: Skips if state file already exists
- **Creates all Harness resources**: Project, connectors, environments, services, monitored services, code repository, etc.

**7. Status Display**
- Shows cluster status, Prometheus deployment, and Terraform results
- Provides clear next steps based on what was configured

### Script Options

```bash
# Skip Docker image build (if you already have the backend image)
./start-demo.sh --skip-docker-build

# Skip Terraform/Harness setup (useful for infrastructure-only testing)
./start-demo.sh --skip-terraform

# Combine options
./start-demo.sh --skip-docker-build --skip-terraform
```

### First Run vs Subsequent Runs

**First Run (Complete Setup):**
- Prompts for:
  - Docker Hub username (unless already logged in via Docker Desktop)
  - Docker Hub password/PAT
  - Harness Account ID
  - Harness Personal Access Token (PAT)
- Saves all credentials to `.demo-config` for future runs
- Creates Harness resources via Terraform
- Takes ~8-12 minutes total (including Docker build and IaC provisioning)

**Subsequent Runs:**
- Detects existing state file and skips Harness resource creation
- Reuses saved credentials from `.demo-config`
- Only prompts if saved credentials are missing or invalid
- Takes ~2-3 minutes for infrastructure verification

### Credential Management

The script stores credentials in `.demo-config` (git-ignored) for convenience:
- **Docker Hub username** - Reused for subsequent runs
- **Harness Account ID** - Saved to avoid re-entering
- **Harness PAT** - Cached for convenience (can also use `DEMO_BASE_PAT` env var)
- **Docker Hub password/PAT** - Saved for Terraform configuration

**Security Notes:**
- `.demo-config` is automatically excluded from Git via `.gitignore`
- Use Personal Access Tokens (PATs) instead of passwords when possible
- Docker Hub PAT: https://hub.docker.com/settings/security
- Harness PAT: Profile > My API Keys & Tokens

**Using Docker Desktop:**
- If you log in to Docker Hub through Docker Desktop, the script detects this and reuses your session
- You won't be prompted for Docker credentials during the build phase

### When Finished with the Demo

```bash
# Clean up deployed applications only
./stop-demo.sh

# Full cleanup (everything - all options below)
./stop-demo.sh --full-cleanup
```

**Shutdown Script Options:**
- `./stop-demo.sh` - Remove deployed applications (frontend/backend)
- `./stop-demo.sh --delete-prometheus` - Also remove Prometheus monitoring
- `./stop-demo.sh --stop-cluster` - Also stop Kubernetes cluster (minikube only)
- `./stop-demo.sh --delete-harness-project` - Delete Harness "Base Demo" project via API
- `./stop-demo.sh --delete-docker-repo` - Delete Docker Hub harness-demo repository via API
- `./stop-demo.sh --delete-config-files` - Delete .demo-config, se-parms.tfvars, and IaC state files
- `./stop-demo.sh --full-cleanup` - Complete cleanup (all of the above)

**API-Based Cleanup Features:**

The script can now clean up Harness and Docker Hub resources using API calls:

- **Harness Project Deletion**: Uses your cached Harness PAT from `.demo-config` to delete the "Base Demo" project and all its resources (pipelines, services, environments, connectors, etc.)
- **Docker Hub Repository Deletion**: Uses your cached Docker credentials to delete the `harness-demo` repository and all its images
- **Interactive Prompts**: Both operations require explicit "yes" confirmation before proceeding

**Example Combinations:**
```bash
# Clean up everything except Kubernetes
./stop-demo.sh --delete-harness-project --delete-docker-repo --delete-config-files

# Clean up only cloud resources (keep local infrastructure)
./stop-demo.sh --delete-harness-project --delete-docker-repo
```

> **Next Steps**: After running `start-demo.sh` successfully:
> 1. Navigate to [app.harness.io](https://app.harness.io) and select the **"Base Demo"** project
> 2. Configure Harness Code Repository (see Step 8 in Manual Setup below)
> 3. Follow the lab guides in the [markdown/](markdown/) directory

---

## Manual Setup

If you prefer manual control or need to troubleshoot, follow these detailed steps:

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

### Step 4: Build and Push Docker Images

> **✅ Automated**: The [start-demo.sh](start-demo.sh) script automatically detects your architecture (Intel/AMD vs Apple Silicon) and builds all images with the correct platform settings. You can skip this step if using the automated script.

> **⚠️ Manual Builds**: If building manually, Harness Cloud runs on amd64 architecture. Apple Silicon users (M1/M2/M3/M4) must use `docker buildx build --platform linux/amd64`.

#### Backend Application Image

```bash
# Navigate to backend directory
cd backend

# Build the Docker image
# Replace "dockerhubaccountid" with YOUR Docker Hub username

# For Intel/AMD Macs and PCs:
docker build -t dockerhubaccountid/harness-demo:backend-latest .

# For Apple Silicon Macs (M1/M2/M3/M4):
docker buildx build --platform linux/amd64 -t dockerhubaccountid/harness-demo:backend-latest --push .

# If not using buildx --push flag, login and push separately:
docker login -u dockerhubaccountid
docker push dockerhubaccountid/harness-demo:backend-latest
```

#### Test Image (for CI Pipeline)

```bash
# Navigate to python-tests directory
cd python-tests

# For Intel/AMD Macs and PCs:
docker build -t dockerhubaccountid/harness-demo:test-latest .
docker push dockerhubaccountid/harness-demo:test-latest

# For Apple Silicon Macs (M1/M2/M3/M4):
docker buildx build --platform linux/amd64 -t dockerhubaccountid/harness-demo:test-latest --push .
```

**Important Docker Image Tags:**
- `backend-latest` - Django backend application (production runtime)
- `test-latest` - Python + pytest environment (CI testing only)
- `demo-base-<tag>` - Frontend Angular application

**Critical**: Remember to replace `dockerhubaccountid` in:
1. The Docker build/push commands above
2. [kit/main.tf](kit/main.tf) line ~300: `imagePath: dockerhubaccountid/harness-demo`
3. Your Harness pipeline's Test Intelligence step to use `test-latest` image

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

### Step 6: Configure IaC Variables

> **Note**: The automated `start-demo.sh` script handles this step automatically. Only follow these manual steps if you skipped the automated setup or used `--skip-terraform`.

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
DOCKER_PAT = "your-dockerhub-pat"
```

**Important**: Also update `dockerhubaccountid` in [kit/main.tf](kit/main.tf) (line ~300) with your Docker Hub username.

### Step 7: Run Terraform to Create Harness Resources

> **Note**: The automated `start-demo.sh` script handles this step automatically. Only follow these manual steps if you skipped the automated setup or used `--skip-terraform`.

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

**What Gets Created** (all in "Base Demo" project):
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

Follow the step-by-step lab guides in the `markdown/` directory which walk through:

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
├── start-demo.sh          # Automated startup script for local infrastructure
├── stop-demo.sh           # Automated shutdown script for cleanup
├── kit/                   # Terraform Infrastructure as Code
│   ├── main.tf            # Main IaC configuration
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

**Issue**: Terraform not found
- **Solution**: Install Terraform from https://www.terraform.io/downloads

**Issue**: Services not accessible at localhost:8080
- **Solution** (minikube): Ensure `minikube tunnel` is running in a separate terminal
- **Solution** (Rancher Desktop): Check that Kubernetes is enabled in preferences

**Issue**: Prometheus connector fails in Harness
- **Solution**: Use ngrok to expose Prometheus and update the connector URL to the ngrok HTTPS URL

**Issue**: Docker image push fails
- **Solution**: Verify you're logged in to Docker Hub: `docker login -u your-username`

**Issue**: Image pull error: "pull access denied for harness-demo"
- **Cause**: The placeholder `dockerhubaccountid` was not replaced with your actual Docker Hub username
- **Solution**:
  1. Update [kit/main.tf](kit/main.tf) line ~300 to use your Docker Hub username: `imagePath: YOUR-USERNAME/harness-demo`
  2. In Harness UI, verify the service artifact configuration shows `YOUR-USERNAME/harness-demo:backend-latest`
  3. Re-run the deployment pipeline

**Issue**: Test Intelligence step fails with "pytest: not found"
- **Cause**: The Test Intelligence step is not using the correct container image
- **Solution**:
  1. Build and push the test image (see architecture notes above for Apple Silicon):
     ```bash
     cd python-tests
     # Apple Silicon: docker buildx build --platform linux/amd64 -t YOUR-USERNAME/harness-demo:test-latest --push .
     # Intel/AMD: docker build -t YOUR-USERNAME/harness-demo:test-latest . && docker push YOUR-USERNAME/harness-demo:test-latest
     ```
  2. In Harness pipeline, update Test Intelligence step to use image: `YOUR-USERNAME/harness-demo:test-latest`
  3. Do NOT use `backend-latest` for testing - use `test-latest`

**Issue**: Test Intelligence fails with "exec /usr/bin/sh: exec format error"
- **Cause**: Docker image was built for wrong architecture (ARM64 instead of amd64)
- **Affects**: Apple Silicon Macs building images for Harness Cloud
- **Solution**: Rebuild the image with `--platform linux/amd64`:
  ```bash
  cd python-tests
  docker buildx build --platform linux/amd64 -t YOUR-USERNAME/harness-demo:test-latest --push .
  ```

**Issue**: Pipeline setup or build infrastructure questions
- **Solution**: The demo uses **Harness Cloud for CI builds** (test and compile steps)
- Requires: Harness account with credit card verification (free tier available)
- In pipeline infrastructure, select:
  - Platform: "Harness Cloud"
  - OS: "Linux"
  - Architecture: "Amd64"

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

To start fresh and reset everything, you have several options:

### Option 1: Complete Automated Cleanup (Recommended)

```bash
# Clean up EVERYTHING (Harness project, Docker repo, local files, K8s resources)
./stop-demo.sh --full-cleanup
```

This single command will:
- Delete the Harness "Base Demo" project via API (with confirmation prompt)
- Delete the Docker Hub `harness-demo` repository via API (with confirmation prompt)
- Delete configuration files (.demo-config, se-parms.tfvars, state files)
- Remove Kubernetes deployments (frontend/backend)
- Remove Prometheus monitoring
- Stop Kubernetes cluster (minikube only)

### Option 2: Selective Automated Cleanup

Choose specific cleanup operations:

```bash
# Clean up only cloud resources (Harness + Docker Hub)
./stop-demo.sh --delete-harness-project --delete-docker-repo

# Clean up cloud resources and local config (keeps K8s running)
./stop-demo.sh --delete-harness-project --delete-docker-repo --delete-config-files

# Clean up only local resources (keeps Harness project)
./stop-demo.sh --delete-prometheus --stop-cluster --delete-config-files
```

### Option 3: Manual Cleanup

**Step 1: Clean Kubernetes Resources**
```bash
# Delete deployed applications
kubectl delete deployment frontend-deployment --ignore-not-found=true
kubectl delete service web-frontend-svc --ignore-not-found=true
kubectl delete deployment backend-deployment --ignore-not-found=true
kubectl delete service web-backend-svc --ignore-not-found=true

# Delete Prometheus (optional)
kubectl delete -f kit/prometheus.yml -n monitoring --ignore-not-found=true
kubectl delete namespace monitoring --ignore-not-found=true
```

**Step 2: Delete Harness Resources**

> **Important**: Delete Harness resources through the UI **before** running `terraform destroy`. This ensures proper cleanup of all dependencies.

1. Navigate to Harness UI > **Code Repository** > Manage Repository
   - Delete **"partner_demo_kit"** repository
2. Navigate to **Projects**
   - Delete **"Base Demo"** project (this removes all project resources)

**Step 3: Clean IaC State**

After deleting Harness resources through the UI:

```bash
cd kit

# Option A: Destroy using Terraform (may have some errors - safe to ignore)
terraform destroy -var="pat=$DEMO_BASE_PAT" -var-file="se-parms.tfvars"

# Option B: Clean slate - remove all state files
git clean -dxf  # WARNING: Removes all untracked files including .tfstate files
```

> **Note**: The destroy command may show errors for resources already deleted through the Harness UI. This is expected and safe to ignore. The cleanup script handles this automatically.

**Step 4: Clean Docker Hub (Optional)**
- Navigate to Docker Hub
- Delete the **"harness-demo"** repository

**Step 5: Stop Kubernetes (Optional)**
```bash
# For minikube
minikube stop

# For Rancher Desktop - stop through the UI
```

## Next Steps

### What Happens After You Complete the Training

Once you've successfully completed the demo labs and built your Harness Home Lab, you're ready to:

1. **Create Your Custom Demo Recording**

   This is your final assessment - a customer pitch recording that demonstrates your mastery of Harness sales enablement. You'll create a 10-15 minute recording where you pitch Harness to a pretend client.

   **Recording Requirements:**
   - Choose a specific use case or industry vertical
   - Customize the demo to address relevant pain points for that vertical
   - Deliver a compelling sales pitch (not just a demo walkthrough)
   - Submit to your Harness Partner Manager for evaluation

   **Evaluation Rubric:**

   Your pitch will be evaluated on five key criteria:

   **1. Understanding of the Module**
   - Accurate description of Harness features and benefits
   - Clear explanation of how Harness addresses customer pain points
   - Technical accuracy and depth of knowledge

   **2. Articulation of Value Proposition**
   - Effective communication of Harness's unique differentiators
   - Ability to align Harness capabilities with specific customer needs
   - Clear ROI and business value messaging

   **3. Opportunity Identification**
   - Demonstration of how to spot potential use cases for Harness
   - Understanding of which customer scenarios are best suited for each module
   - Ability to qualify opportunities and map features to pain points

   **4. Presentation Skills**
   - Clear and confident delivery
   - Logical flow of information
   - Professional communication style
   - Engaging storytelling and customer-focused narrative

   **5. Customization and Internalization**
   - Evidence that you've made the pitch your own, not just repeating scripted content
   - Integration of training materials with your own insights and examples
   - Authenticity and personal style in delivery
   - Creative adaptation of demo scenarios to customer context

2. **Apply Your Skills**
   - Use this environment for customer proof-of-concepts
   - Adapt the demo for specific customer scenarios
   - Build additional demo scenarios using the same infrastructure

3. **Stay Current**
   - Join Harness partner community events and webinars
   - Access updated demo materials and best practices
   - Share your customizations and learnings with other partners

4. **Get Certified**
   - Complete Harness certification programs
   - Earn Harness professional badges
   - Advance your partner enablement journey

## Resources & Support

- **Lab Guides**: See [markdown/](markdown/) directory for step-by-step instructions
- **Harness Documentation**: [docs.harness.io](https://docs.harness.io)
- **Automation Scripts**: [start-demo.sh](start-demo.sh) and [stop-demo.sh](stop-demo.sh)

For questions or assistance:
- Contact your Harness Partner Manager
- Submit issues via [GitHub](https://github.com/harness-community/partner-demo-kit/issues)
- Join the Harness Partner Community

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
