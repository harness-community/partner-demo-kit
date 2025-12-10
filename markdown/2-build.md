# Lab 2: CI Pipeline with Test Intelligence

> **Important**: All activities in the **"Base Demo"** project

## Overview
This lab walks through creating a complete CI pipeline with test intelligence, compilation, and Docker image building. You'll see how Harness Cloud provides instant, autoscaling build infrastructure without any setup.

## Prerequisites
- Harness account with CI module enabled
- "Base Demo" project created by Terraform
- Docker Hub account with `harness-demo` repository

## Step 1: Create a New Pipeline

1. In Harness UI, navigate to **Pipelines** in the "Base Demo" project
2. Click **+ Create Pipeline**
   - **Name**: `Workshop Build and Deploy`
   - **Store**: Inline (for simplicity)
3. Click **Create**

> **Note**: Inline vs. Remote - We're using inline for this lab, but you can store pipelines in Git repositories alongside your application code.

## Step 2: Add a Build Stage

1. Click **+ Add Stage**
2. Select **Build** as the stage type
3. Configure the build stage:
   - **Stage Name**: `Build`
   - **Clone Codebase**: Enable
   - **Repository Name**: `partner_demo_kit` (the Harness Code repository created by Terraform)
4. Click **Set Up Stage**

## Step 3: Configure Infrastructure (Harness Cloud)

1. On the **Infrastructure** tab
2. Select **Harness Cloud**
3. Click **Continue**

> **Important**: Choose the architecture that matches your computer:
> - **arm64** - If using Apple Silicon (M1/M2/M3)
> - **amd64** - If using Intel processors

> **Note**: With zero configuration (just one click!), you've set up an autoscaling build environment in the cloud that:
> - Requires no management
> - Uses the fastest bare-metal hardware available
> - Is dramatically less expensive than on-premise solutions

## Step 4: Add Test Intelligence Step

1. On the **Execution** tab, click **+ Add Step**
2. Select **Add Step** > **Test Intelligence**
3. Configure:
   - **Name**: `Test Intelligence`
   - **Command**:
     ```bash
     cd ./python-tests
     pytest
     ```
4. Click **Apply Changes**

> **What is Test Intelligence?**
> Test Intelligence accelerates test cycles by up to 80% by running only relevant tests based on code changes. This means:
> - Faster builds
> - Shorter feedback loops
> - Significant cost savings

## Step 5: Add Compile Step (Using Template)

1. Click **+ Add Step**
2. Select **Use Template**
3. Select the **"Compile Application"** template (created by Terraform)
4. Configure:
   - **Name**: `Compile`
5. Click **Apply Changes**

> This template was created by Terraform and standardizes the frontend compilation process across all builds.

## Step 6: Add Docker Build and Push Step

1. Click **+ Add Step**
2. Select **Add Step** > **Build and Push an image to Docker Registry**
3. Configure:
   - **Name**: `Push to Dockerhub`
   - **Docker Connector**: `workshop-docker` (created by Terraform)
   - **Docker Repository**: `dockerhubaccountid/harness-demo`
     - ⚠️ Replace `dockerhubaccountid` with YOUR Docker Hub username
   - **Tags**: Click **+ Add**
     - Add: `demo-base-<+pipeline.sequenceId>`
     - Change field type to **Expression** using the icon
   - **Optional Configuration** (expand):
     - **Dockerfile**: `/harness/frontend-app/harness-webapp/Dockerfile`
     - **Context**: `/harness/frontend-app/harness-webapp`
4. Click **Apply Changes**

## Step 7: Save and Run the Pipeline

1. Click **Save** in the top right
2. Click **Run**
3. Select **Branch**: `main`
4. Click **Run Pipeline**

## Monitor the Execution

Watch the pipeline execute:
- ✅ **Test Intelligence** - Runs Python tests
- ✅ **Compile** - Builds the Angular frontend
- ✅ **Push to Dockerhub** - Builds and pushes the Docker image

## Verify the Results

1. **Check the pipeline execution** in Harness - all steps should be green
2. **Verify the Docker image** was pushed:
   - Visit: `https://hub.docker.com/r/dockerhubaccountid/harness-demo/tags`
   - You should see a new tag: `demo-base-1` (or higher sequence number)

## Key Takeaways

- **Harness Cloud** provides instant, zero-config build infrastructure
- **Test Intelligence** optimizes test execution for faster feedback
- **Templates** standardize build processes across teams
- **Docker integration** makes artifact management seamless
- **Pipeline as Code** can be stored inline or in Git

## Pipeline Configuration Summary

Your pipeline now has these stages:
- **Build** stage with:
  - Test Intelligence (pytest)
  - Compile Application (Angular build)
  - Docker Build & Push (to Docker Hub)

---

**Next**: Proceed to [Lab 3: Frontend Deployment](3-cd-frontend.md)
