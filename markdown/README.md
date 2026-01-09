# Harness Partner Demo Kit

> A comprehensive hands-on demonstration of Harness platform capabilities running entirely on local infrastructure.

## 🚀 Welcome

This demo kit showcases the complete Harness platform including CI/CD, Code Repository, Continuous Verification, and Security Testing. Everything runs on your local Kubernetes cluster (Colima for Apple Silicon, minikube, or Rancher Desktop) to minimize external dependencies.

**All resources are created in a "Base Demo" project**, keeping demo resources segregated from production environments.

---

## 📚 Lab Modules

<div class="lab-card">

### <span class="lab-number">Lab 0</span> [Getting Started & Setup](0-login.md)

Set up your local environment, verify prerequisites, and ensure all infrastructure components are ready.

**Topics:** Infrastructure setup, Harness account configuration, Kubernetes cluster verification

</div>

<div class="lab-card">

### <span class="lab-number">Lab 1</span> [Code Repository Secret Scanning](1-coderepo.md)

Discover how Harness Code Repository prevents secrets from being committed to your codebase.

**Topics:** Secret scanning, Git credential management, proactive security

</div>

<div class="lab-card">

### <span class="lab-number">Lab 2</span> [CI Pipeline Setup](2-build.md)

Build and test your application using Harness CI with Test Intelligence and containerization.

**Topics:** Build pipelines, test intelligence, Docker image creation

</div>

<div class="lab-card">

### <span class="lab-number">Lab 3</span> [Frontend Deployment](3-cd-frontend.md)

Deploy the Angular frontend application using a rolling deployment strategy.

**Topics:** Kubernetes deployments, rolling updates, service configuration

</div>

<div class="lab-card">

### <span class="lab-number">Lab 4</span> [Backend Canary Deployment](4-cd-backend.md)

Implement a canary deployment strategy for the Django backend with progressive rollout.

**Topics:** Canary deployments, traffic splitting, progressive delivery

</div>

<div class="lab-card">

### <span class="lab-number">Lab 5</span> [Continuous Verification](6-cv.md)

Use Prometheus metrics to automatically verify deployment health and rollback on issues.

**Topics:** Health verification, Prometheus integration, automated rollback

</div>

<div class="lab-card">

### <span class="lab-number">Lab 6</span> [Security Scanning](5-security.md)

Integrate security scanning into your pipeline to detect vulnerabilities early.

**Topics:** Security testing, vulnerability detection, compliance *(requires licensed partner org)*

</div>

<div class="lab-card">

### <span class="lab-number">Lab 7</span> [OPA Policy Enforcement](7-opa.md)

Enforce governance policies across your deployments using Open Policy Agent.

**Topics:** Policy as code, governance, compliance automation *(requires licensed partner org)*

</div>

---

## 🛠️ Tech Stack

- **Frontend:** Angular 17, TypeScript, Harness Feature Flags SDK
- **Backend:** Django 5.0, Python, PostgreSQL
- **Infrastructure:** Kubernetes (Colima/minikube/Rancher Desktop), Prometheus
- **IaC:** Terraform for Harness resource provisioning

## 📖 Quick Links

- [Harness Documentation](https://developer.harness.io)
- [GitHub Repository](https://github.com/harness-community/partner-demo-kit)
- [Support & Issues](https://github.com/harness-community/partner-demo-kit/issues)

---

**Ready to start?** Begin with [Lab 0: Getting Started](0-login.md)
