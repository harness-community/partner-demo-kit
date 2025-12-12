# Demo Documentation

This directory contains the workshop documentation rendered with [Docsify](https://docsify.js.org/).

## Quick Start (Local Preview)

```bash
# Install docsify-cli
npm i -g docsify-cli

# Serve locally
cd markdown
docsify serve .

# Access at http://localhost:3000
```

## Deploy to Kubernetes

### 1. Build the Docker image

```bash
cd markdown
docker build -t <your-dockerhub-username>/harness-demo:docs-latest .
docker push <your-dockerhub-username>/harness-demo:docs-latest
```

### 2. Update the K8s manifest

Edit `harness-deploy/docs/docs-deployment.yaml` and replace `dockerhubaccountid` with your Docker Hub username.

### 3. Deploy to K8s

```bash
kubectl apply -f harness-deploy/docs/docs-deployment.yaml
```

### 4. Access the docs

- **Minikube**: `minikube service docs-service` or `http://localhost:30001` (with minikube tunnel running)
- **Rancher Desktop**: `http://localhost:30001`

## Documentation Structure

- **0-login.md** - Initial setup and login
- **1-coderepo.md** - Code Repository secret scanning
- **2-build.md** - CI pipeline setup
- **3-cd-frontend.md** - Frontend deployment
- **4-cd-backend.md** - Backend canary deployment
- **5-cv.md** - Continuous verification
- **6-sto.md** - Security scanning
- **7-opa.md** - OPA policy enforcement

## Customization

Edit `index.html` to customize Docsify configuration, themes, and plugins.
