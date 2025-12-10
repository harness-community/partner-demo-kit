# Lab 6: Continuous Verification

> **Important**: All activities in the **"Base Demo"** project

## Overview
This lab adds Continuous Verification (CV) to your backend canary deployment. Harness CV uses machine learning to analyze metrics from Prometheus and automatically detect anomalies during deployment, enabling automated rollback if issues are detected.

## Prerequisites
- Completed Lab 4 (Backend Deployment)
- Backend service deployed with canary strategy
- Prometheus running in your Kubernetes cluster
- Monitored service `backend_dev` created by Terraform

## Step 1: Add Verify Step to Backend Deployment

1. In the Pipeline Studio, navigate to the **Backend - Deployment** stage
2. Click on the **Execution** tab
3. **After** the **Canary Deployment** step, click **+ Add Step**
4. Select **Add Step** > **Verify**

## Step 2: Configure the Verify Step

Configure the Verify step with these details:

**Verify Configuration:**
- **Name**: `Verify`
- **Continuous Verification Type**: `Canary`
- **Sensitivity**: `Low`
- **Duration**: `5 mins`

Click **Apply Changes**

> **What is Sensitivity?**
> This defines how sensitive the ML algorithms are to deviations from the baseline:
> - **Low**: More tolerant of variations (good for initial testing)
> - **Medium**: Balanced detection
> - **High**: Strict detection, flags smaller anomalies

## Step 3: Save and Run the Pipeline

1. Click **Save** in the top right
2. Click **Run**
3. Configure the run:
   - **Branch Name**: `main`
   - **Stage: Frontend - Deployment**
     - **Primary Artifact**: `frontend`
   - **Stage: Backend - Deployment**
     - **Primary Artifact**: `backend`
4. Click **Run Pipeline**

## Monitor the Verification

Watch the pipeline execute through all stages:
- ✅ **Build** - CI pipeline
- ✅ **Frontend - Deployment** - Rolling deployment
- ✅ **Backend - Deployment** - Canary deployment with verification

The **Verify** step will take 5 minutes to complete while it analyzes metrics from Prometheus.

## Test the Application During Verification

While the canary deployment and verification are running, test the application:

**Ensure minikube tunnel is running** (if using minikube):
```bash
# In a separate terminal
minikube tunnel
```

### Spot the Canary!

1. Open browser to: http://localhost:8080
2. Keep clicking the **"Check Release"** button
3. Look for a **yellow cartoon graphic** - that's the canary!
   - This special graphic is served only by canary pods
   - It demonstrates that traffic is being sent to the canary version

### Distribution Test

1. Click **"Distribution Test"** > **"Start"** button
2. Click the **Play (▶️)** button
3. Watch the traffic distribution graph build out
   - This shows how requests are distributed across backend pods
   - During canary deployment, you'll see traffic split between stable and canary pods

## View Verification Results

After the Verify step completes:

1. In the Harness UI, click on the **Verify** step in the pipeline execution
2. Toggle **Console View** to see detailed metrics
3. Uncheck **"Display only anomalous metrics and affected nodes"** to see all metrics
4. Click the **⏷** dropdown to view the details

You'll see:
- Metrics collected from Prometheus
- Baseline comparison data
- ML analysis results
- Pass/fail status for each metric

## How Continuous Verification Works

Harness CV integrates with APMs and logging tools to verify deployments are running safely and efficiently:

1. **Baseline Learning**: CV learns normal behavior from previous successful deployments
2. **Real-time Analysis**: During deployment, CV collects metrics and compares them to the baseline
3. **ML Detection**: Machine learning algorithms identify anomalies
4. **Automated Action**: If anomalies exceed the sensitivity threshold, CV can automatically trigger a rollback

> **Key Benefit**: Automatic rollback on anomalies means safer deployments with less manual monitoring required.

## Verify the Deployment

### Check Kubernetes Resources

```bash
# View all deployments
kubectl get pods -A | grep deployment

# View all services
kubectl get services -A | grep svc
```

You should see:
- `frontend-deployment` pods
- `backend-deployment` pods (now fully promoted after successful canary + verification)
- `web-frontend-svc` service
- `web-backend-svc` service

## Key Takeaways

- **Continuous Verification** adds ML-powered safety gates to deployments
- **Prometheus integration** provides metrics for analysis without additional instrumentation
- **Automated rollback** reduces risk by catching issues before full rollout
- **Sensitivity tuning** allows you to balance between false positives and detection accuracy
- **Monitored services** (like `backend_dev`) define which metrics to analyze

## What You've Built

Your complete pipeline now includes:
1. **Build** stage
   - Test Intelligence
   - Compile Application
   - Docker Build & Push
2. **Frontend - Deployment** stage
   - Rolling deployment
3. **Backend - Deployment** stage
   - Canary deployment
   - Automated traffic shifting
   - **Continuous Verification (new!)**
   - ML-powered anomaly detection

---

**Next**: Proceed to [Lab 7: OPA Policy Enforcement](7-opa.md)

> **Note**: Lab 5 (Security Testing) and Lab 7 (OPA Policy) are available only with a licensed partner organization
