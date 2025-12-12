# Lab 0: Getting Started

> **Important**: All activities in the **"Base Demo"** project

## About This Partner Demo Kit

This is the **Base Partner Demo Kit** - one of two comprehensive demo kits available for Harness partners:

1. **Base Partner Demo Kit** (this kit) - Covers core Harness capabilities:
   - Code Repository with Secret Scanning
   - CI Pipeline with Test Intelligence
   - Continuous Deployment (Rolling and Canary strategies)
   - Continuous Verification with Prometheus

2. **Advanced Partner Demo Kit** - Extends the base kit with licensed features:
   - Security Testing Orchestration (STO)
   - Software Supply Chain Assurance (SSCA)
   - OPA Policy Enforcement
   - Advanced governance capabilities

> **Note**: The advanced features (Labs 5 and 7) require a licensed partner organization. This base kit can be completed with a free Harness account.

## Overview
This guide helps you get started with the Harness Partner Demo Kit. Before proceeding with the individual labs, ensure you have completed all setup steps and can access your Harness account.

## Prerequisites

Before starting the labs, ensure you have completed:

1. **Harness Account Setup**
   - Free Harness account with CI, CD, and Code Repository
   - Harness delegate installed at account level (Helm-based recommended)

2. **Local Environment Setup**
   - Docker Engine running
   - Kubernetes cluster: Rancher Desktop (recommended) or minikube
   - Terraform or Open Tofu installed
   - kubectl and helm installed
   - Git client installed

3. **Docker Hub Account**
   - Docker Hub account created
   - Repository `harness-demo` created in Docker Hub
   - Docker Hub Personal Access Token (PAT) generated

4. **Terraform Provisioning Completed**
   - Ran `terraform apply` from the `kit/` directory
   - Verified "Base Demo" project was created in Harness
   - Verified `partner_demo_kit` Code Repository was created

## Access Your Harness Account

1. Navigate to [app.harness.io](https://app.harness.io)
2. Log in with your Harness credentials
3. **Select the "Base Demo" project** from the project picker

> **Important**: All lab activities take place in the **"Base Demo"** project. This keeps demo resources separate from production environments.

## Verify Your Setup

Before proceeding to Lab 1, verify:

### 1. Harness Resources Created by Terraform

Navigate to the **"Base Demo"** project and verify:

**Code Repository:**
- Repository: `partner_demo_kit` exists

**Connectors:**
- `workshop-docker` - Docker Hub connector
- `workshop_k8s` - Kubernetes connector (for local cluster)
- Prometheus connector (for continuous verification)

**Environments:**
- `Dev` environment created
- `K8s Dev` infrastructure definition created

**Services:**
- `backend` service pre-configured with K8s manifests

**Templates:**
- `Compile Application` step template created

**Monitored Services:**
- `backend_dev` monitored service for continuous verification

### 2. Local Kubernetes Cluster Running

**With Rancher Desktop:**
```bash
# Check cluster status
kubectl cluster-info

# Should see Kubernetes control plane running
```

**With minikube:**
```bash
# Check cluster status
minikube status

# Should show: host, kubelet, and apiserver running
```

### 3. Prometheus Deployed

```bash
# Check Prometheus pod
kubectl get pods -n monitoring

# Should see prometheus-k8s-0 pod running
```

### 4. Docker Hub Access - NOT SURE WE NEED TO CHECK THIS?

```bash
# Test Docker login
docker login

# Verify you can push to your repository
docker pull hello-world
docker tag hello-world dockerhubaccountid/harness-demo:test
docker push dockerhubaccountid/harness-demo:test
```

Replace `dockerhubaccountid` with your actual Docker Hub username.

## Troubleshooting

### Can't Find "Base Demo" Project
- Verify Terraform completed successfully
- Check Harness UI > Projects to see if project exists
- Re-run `terraform apply` if needed

### Kubernetes Cluster Not Accessible
**Rancher Desktop:**
- Check Rancher Desktop is running
- Verify Kubernetes is enabled in Settings

**Minikube:**
- Run `minikube start` to start the cluster
- Run `minikube status` to verify

### Prometheus Not Running
```bash
# Reinstall Prometheus
cd kit
kubectl create namespace monitoring
kubectl -n monitoring apply -f ./prometheus.yml
```

### Docker Push Fails
- Verify Docker Hub credentials in `kit/se-parms.tfvars`
- Check Docker Hub repository `harness-demo` exists
- Verify you're logged into Docker Hub: `docker login`

## Lab Structure

The demo consists of these labs:

1. **Lab 1: Code Repository Secret Scanning** - Prevent secrets from being committed
2. **Lab 2: CI Pipeline** - Build with test intelligence and Docker push
3. **Lab 3: Frontend Deployment** - Rolling deployment to Kubernetes
4. **Lab 4: Backend Deployment** - Canary deployment strategy
5. **Lab 5: Security Testing** - (Requires licensed partner org)
6. **Lab 6: Continuous Verification** - ML-powered deployment validation
7. **Lab 7: OPA Policy Enforcement** - (Requires licensed partner org)

## Important Notes

- All demo activities use the **"Base Demo"** project
- The `partner_demo_kit` repository in Harness Code is a mirror of the GitHub repository
- You'll need to generate Git credentials for the Harness Code Repository (covered in Lab 1)
- Keep a terminal with `minikube tunnel` running throughout the demo (if using minikube)
- Rancher Desktop users don't need a tunnel - services are automatically accessible

---

**Next**: Proceed to [Lab 1: Code Repository Secret Scanning](1-coderepo.md)
