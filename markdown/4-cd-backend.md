# Lab 4: Continuous Deployment - Backend (Canary)

> **Important**: All activities in the **"Base Demo"** project

## Overview
This lab adds backend deployment using a Canary deployment strategy. Unlike the frontend's rolling deployment, canary deployments gradually shift traffic to new versions while monitoring for issues.

## Prerequisites
- Completed Lab 3 (Frontend Deployment)
- Backend service created by Terraform (already exists in "Base Demo" project)
- Application accessible at http://localhost:8080

## Step 1: Add Backend Deploy Stage

1. In the Pipeline Studio, click **+ Add Stage** (after Frontend - Deployment)
2. Select **Deploy** as the stage type
3. Configure:
   - **Stage Name**: `Backend - Deployment`
   - **Deployment Type**: `Kubernetes`
4. Click **Set Up Stage**

## Step 2: Select Backend Service

On the **Service** tab:

1. Click **Select Service** (not "Add Service" - it already exists!)
2. Select **backend** (this was pre-configured by Terraform)
3. Click **Continue**

> **Note**: The backend service was created by Terraform and includes:
> - Kubernetes manifests from `harness-deploy/backend/`
> - Docker artifact configuration pointing to `dockerhubaccountid/harness-demo:backend-latest`

## Step 3: Propagate Environment from Frontend

On the **Environment** tab:

1. Click **Propagate Environment From**
2. Select **Stage [Frontend - Deployment]**
3. Click **Continue**

> **Why Propagate?**
> Both frontend and backend deploy to the same environment (Dev) and infrastructure (K8s Dev). Propagating ensures consistency and reduces configuration.

## Step 4: Choose Canary Deployment Strategy

On the **Execution** tab:

1. Select **Canary** deployment strategy
2. Click **Use Strategy**

> **What is Canary Deployment?**
> Canary deployment gradually rolls out changes to a small subset of users before rolling out to the entire infrastructure. This allows you to:
> - Test in production with minimal risk
> - Catch issues before full rollout
> - Automatically rollback if problems are detected
>
> The default canary strategy:
> 1. Deploys canary pods (small percentage of traffic)
> 2. Monitors performance and errors
> 3. Promotes to full deployment if healthy
> 4. Can automatically rollback if issues detected

## Step 5: Save and Run the Pipeline

1. Click **Save** in the top right
2. Click **Run**
3. Configure the run:
   - **Branch Name**: `main`
   - **Stage: Frontend - Deployment**
     - **Primary Artifact**: `frontend`
   - **Stage: Backend - Deployment**
     - **Primary Artifact**: `backend`
4. Click **Run Pipeline**

## Monitor the Deployment

Watch all three stages execute:
- ✅ **Build** - CI pipeline
- ✅ **Frontend - Deployment** - Rolling deployment
- ✅ **Backend - Deployment** - Canary deployment (watch the canary phases!)

## Verify the Deployment

### Check Kubernetes Resources

```bash
# View all deployments
kubectl get pods -A | grep deployment

# View all services
kubectl get services -A | grep svc
```

You should now see:
- `frontend-deployment` pods
- `backend-deployment` pods (including canary pods during deployment)
- `web-frontend-svc` service
- `web-backend-svc` service

### Test the Application

**Ensure minikube tunnel is running** (if using minikube):
```bash
# In a separate terminal
minikube tunnel
```

**Access the demo app**:
1. Open browser to: http://localhost:8080
2. Click **"Distribution Test"** > **"Start"** button
3. Click the **Play (▶️)** button
4. Watch the traffic distribution graph build out

This graph shows how requests are distributed across the backend pods!

### Spot the Canary!

During canary deployments, a special "canary" feature is enabled:
- Keep clicking the **"Check Release"** button
- Look for a **yellow cartoon graphic** - that's the canary!
- This graphic is served only by canary pods

## Key Takeaways

- **Canary deployments** reduce risk by gradual rollout
- **Service propagation** ensures consistency across related deployments
- **Pre-configured services** (via Terraform) streamline demo setup
- **Canary phases** (deploy → monitor → promote) provide safety gates
- **Traffic shifting** can be observed in real-time

## What You've Built

Your complete pipeline now includes:
1. **Build** stage
   - Test Intelligence
   - Compile Application
   - Docker Build & Push
2. **Frontend - Deployment** stage
   - Rolling deployment
3. **Backend - Deployment** stage (new!)
   - Canary deployment
   - Automated traffic shifting

---

**Next**: Proceed to [Lab 6: Continuous Verification](6-cv.md) to add automated deployment validation

> **Note**: Lab 5 (Security Testing) is available only with a licensed partner organization
