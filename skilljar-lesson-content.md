# Skilljar Lesson: Hands-On Lab Content

## Title
```
Hands-On Lab: Navigate the {Unscripted} Demo Track
```

## Summary
```
In this hands-on lab, you'll perform the exact demonstration you just watched in the video, but this time with your own hands at the controls. Through your local Harness Home Lab environment, you'll gain immediate access to a fully provisioned Harness platform with all necessary resources—such as container registry, test applications, and a deployment cluster. This lab is a vital step in your technical sales journey. By performing these operations yourself in a controlled setting, you'll build the muscle memory and deep understanding needed to confidently recreate and customize these demonstrations for your customers. The lab environment offers a 'golden path' implementation that serves as your reference point, making troubleshooting much easier when you start building your own demos from scratch in later lessons.
```

## Content (HTML)
```html
<div class="lab-instructions">
  <h2>Welcome to Your Hands-On Lab Experience</h2>

  <p>Now it's time to get hands-on! In this lab, you'll execute the complete Harness demonstration using your own <strong>Harness Home Lab</strong> environment. This isn't a simulated environment—this is your own fully functional Harness platform running locally on your machine.</p>

  <div class="callout callout-info">
    <h3>🎯 Lab Objectives</h3>
    <p>By the end of this hands-on lab, you will have:</p>
    <ul>
      <li>Executed all seven core Harness demonstrations from start to finish</li>
      <li>Built muscle memory for navigating the Harness platform</li>
      <li>Developed deep understanding of how each module addresses customer pain points</li>
      <li>Created a reference implementation you can customize for customer scenarios</li>
    </ul>
  </div>

  <h3>Prerequisites</h3>
  <p>Before starting this lab, ensure you have completed:</p>
  <ul>
    <li>✅ Cloned the partner-demo-kit repository to your local machine</li>
    <li>✅ Ran the automated <code>start-demo.sh</code> script successfully</li>
    <li>✅ Verified your Kubernetes cluster is running (Colima for Apple Silicon, or minikube/Rancher Desktop for others)</li>
    <li>✅ Confirmed all Harness resources were created in the "Base Demo" project</li>
    <li>✅ Generated Harness Code Repository credentials in Harness UI</li>
  </ul>

  <div class="callout callout-warning">
    <h3>⚠️ Not Set Up Yet?</h3>
    <p>If you haven't completed the infrastructure setup, <strong>complete the previous lesson first: "Infrastructure Setup: Building Your Harness Home Lab"</strong>. The automated <code>start-demo.sh</code> script handles all infrastructure provisioning and takes approximately 8-12 minutes on first run.</p>
    <p>The script will:</p>
    <ul>
      <li>Check and offer to install missing dependencies (Apple Silicon: Colima, qemu, lima-additional-guestagents)</li>
      <li>Start your Kubernetes cluster (Colima for Apple Silicon, minikube/Rancher Desktop for others)</li>
      <li>Deploy Prometheus for continuous verification</li>
      <li>Build and push Docker images to your Docker Hub account</li>
      <li>Provision all Harness resources using Terraform</li>
      <li>Configure secrets and connectors automatically</li>
    </ul>
  </div>

  <h3>Lab Structure: Seven Progressive Modules</h3>
  <p>This hands-on lab consists of seven progressive modules that build on each other. Follow them in order for the best learning experience.</p>

  <div class="lab-modules">
    <h4>Lab 0: Login & Setup</h4>
    <p><strong>Duration:</strong> 10 minutes</p>
    <p>Verify your environment is ready and access your Harness account. You'll confirm that all Harness resources were created in the "Base Demo" project and generate your Code Repository credentials.</p>
    <p><a href="https://github.com/harness-community/partner-demo-kit/blob/main/markdown/0-login.md" target="_blank">📄 Access Lab 0 Guide</a></p>

    <hr>

    <h4>Lab 1: Code Repository Secret Scanning</h4>
    <p><strong>Duration:</strong> 15 minutes</p>
    <p>Learn how Harness Code Repository protects your organization by detecting and blocking secrets before they're committed. You'll attempt to commit a file containing a secret token and see Harness block it in real-time.</p>
    <p><strong>Key Skills:</strong> Secret scanning, code repository security, developer workflow protection</p>
    <p><a href="https://github.com/harness-community/partner-demo-kit/blob/main/markdown/1-coderepo.md" target="_blank">📄 Access Lab 1 Guide</a></p>

    <hr>

    <h4>Lab 2: CI Pipeline Setup</h4>
    <p><strong>Duration:</strong> 25 minutes</p>
    <p>Build a complete CI pipeline with Test Intelligence and Docker image compilation. You'll create a pipeline that runs tests, uses the "Compile Application" template, and pushes images to Docker Hub—all running on Harness Cloud infrastructure.</p>
    <p><strong>Key Skills:</strong> Pipeline creation, Test Intelligence, Harness Cloud, template usage, artifact publishing</p>
    <p><a href="https://github.com/harness-community/partner-demo-kit/blob/main/markdown/2-build.md" target="_blank">📄 Access Lab 2 Guide</a></p>

    <hr>

    <h4>Lab 3: Frontend Deployment</h4>
    <p><strong>Duration:</strong> 20 minutes</p>
    <p>Deploy the Angular frontend application using a rolling deployment strategy to your local Kubernetes cluster. You'll configure services, environments, and execute your first CD pipeline.</p>
    <p><strong>Key Skills:</strong> CD pipeline setup, rolling deployments, Kubernetes deployment, service configuration</p>
    <p><a href="https://github.com/harness-community/partner-demo-kit/blob/main/markdown/3-cd-frontend.md" target="_blank">📄 Access Lab 3 Guide</a></p>

    <hr>

    <h4>Lab 4: Backend Canary Deployment</h4>
    <p><strong>Duration:</strong> 30 minutes</p>
    <p>Execute a sophisticated canary deployment of the Django backend with automated verification. You'll deploy in phases, verify canary health, and see the full power of Harness CD with Continuous Verification.</p>
    <p><strong>Key Skills:</strong> Canary deployments, continuous verification, Prometheus metrics, progressive delivery</p>
    <p><a href="https://github.com/harness-community/partner-demo-kit/blob/main/markdown/4-cd-backend.md" target="_blank">📄 Access Lab 4 Guide</a></p>

    <hr>

    <h4>Lab 5: Security Scanning</h4>
    <p><strong>Duration:</strong> 20 minutes</p>
    <p><em>Note: Requires licensed partner organization (not available in free tier)</em></p>
    <p>Integrate security scanning into your CI pipeline to detect vulnerabilities in code, containers, and dependencies before they reach production.</p>
    <p><strong>Key Skills:</strong> Security testing integration, vulnerability scanning, shift-left security</p>
    <p><a href="https://github.com/harness-community/partner-demo-kit/blob/main/markdown/5-security.md" target="_blank">📄 Access Lab 5 Guide</a></p>

    <hr>

    <h4>Lab 6: Continuous Verification</h4>
    <p><strong>Duration:</strong> 25 minutes</p>
    <p>Deep dive into how Harness uses Prometheus metrics to automatically verify deployment health. You'll see how continuous verification prevents bad deployments from reaching production.</p>
    <p><strong>Key Skills:</strong> Metrics-based verification, health monitoring, automated rollback triggers</p>
    <p><a href="https://github.com/harness-community/partner-demo-kit/blob/main/markdown/6-cv.md" target="_blank">📄 Access Lab 6 Guide</a></p>

    <hr>

    <h4>Lab 7: OPA Policy Enforcement</h4>
    <p><strong>Duration:</strong> 25 minutes</p>
    <p><em>Note: Requires licensed partner organization (not available in free tier)</em></p>
    <p>Implement governance guardrails using Open Policy Agent (OPA) to enforce deployment standards, security policies, and compliance requirements.</p>
    <p><strong>Key Skills:</strong> Policy as code, OPA policy creation, governance automation, compliance enforcement</p>
    <p><a href="https://github.com/harness-community/partner-demo-kit/blob/main/markdown/7-opa.md" target="_blank">📄 Access Lab 7 Guide</a></p>
  </div>

  <h3>How to Navigate the Labs</h3>
  <ol>
    <li><strong>Access the Lab Guides:</strong> Open <code>http://localhost:30001</code> in your browser to access the deployed documentation. All lab guides are also available in the <code>markdown/</code> directory of your cloned repository, or click the links above to view them on GitHub.</li>
    <li><strong>Set Up Your Browser Workspace:</strong> For the best experience, use one of these approaches:
      <ul>
        <li><strong>Recommended:</strong> Use Chrome's <strong>split tab view</strong> or <strong>two separate browser windows</strong>—Harness UI (app.harness.io) on the left and lab documentation (localhost:30001) on the right. This allows you to reference instructions while working.</li>
        <li><strong>Alternative:</strong> Use a second monitor if available—Harness UI on one screen, lab guide on the other.</li>
      </ul>
    </li>
    <li><strong>Follow Step-by-Step Instructions:</strong> Each lab includes detailed screenshots and commands. Don't skip steps—they build on each other.</li>
    <li><strong>Access Your Demo Application:</strong> Your application will be accessible at <code>http://localhost:8080</code> once deployed (Colima and Rancher Desktop auto-expose; minikube requires <code>minikube tunnel</code>).</li>
    <li><strong>Take Notes:</strong> Document any customizations or insights—you'll use these when creating your final pitch recording.</li>
    <li><strong>Experiment:</strong> After completing each lab as written, try variations. What happens if you change deployment strategies? How do different metrics affect verification?</li>
  </ol>

  <div class="callout callout-success">
    <h3>💡 Pro Tips for Success</h3>
    <ul>
      <li><strong>Complete Labs 0-4 First:</strong> These are the core demonstrations that work on all accounts. Labs 5 and 7 require licensed features.</li>
      <li><strong>Watch for the "Canary" Feature:</strong> When you deploy the backend with canary, look for the yellow cartoon graphic in the distribution test UI—this visual indicator shows which pods are serving the canary version.</li>
      <li><strong>Understand the "Why":</strong> Don't just execute steps—understand WHY each step matters to customers. What pain point does it solve? What's the business value?</li>
      <li><strong>Screenshot Your Success:</strong> Capture screenshots of successful deployments, metrics, and verification steps. You can use these in customer presentations.</li>
      <li><strong>Time Your Demos:</strong> Practice running each lab while timing yourself. Knowing how long each module takes helps you plan customer demonstrations.</li>
    </ul>
  </div>

  <h3>Troubleshooting Resources</h3>
  <p>If you encounter issues during the labs, consult these resources:</p>
  <ul>
    <li><strong>README Troubleshooting Section:</strong> The repository README includes common issues and solutions</li>
    <li><strong>Verify Infrastructure:</strong> Run <code>kubectl cluster-info</code> and <code>kubectl get pods -A</code> to check your cluster health</li>
    <li><strong>Check Harness Delegate:</strong> Ensure your delegate is connected in the Harness UI</li>
    <li><strong>Review Terraform State:</strong> Confirm all resources were created by checking the Harness "Base Demo" project</li>
    <li><strong>GitHub Issues:</strong> Submit issues at <a href="https://github.com/harness-community/partner-demo-kit/issues" target="_blank">github.com/harness-community/partner-demo-kit/issues</a></li>
  </ul>

  <h3>What Comes Next?</h3>
  <p>After completing all seven labs, you'll have:</p>
  <ul>
    <li>✅ Hands-on experience with the complete Harness platform</li>
    <li>✅ A working reference implementation you can customize</li>
    <li>✅ Deep understanding of how to map Harness features to customer pain points</li>
    <li>✅ The technical foundation needed for your final pitch recording</li>
  </ul>

  <p>Once you've completed these labs, you'll move to the final lesson: <strong>Create and Submit Your Custom Demo Recording</strong>, where you'll demonstrate your ability to sell Harness to a prospective client.</p>

  <div class="callout callout-primary">
    <h3>🚀 Ready to Begin?</h3>
    <p>Start with <strong>Lab 0: Login & Setup</strong> to verify your environment and begin your hands-on journey. Remember: this is your chance to build muscle memory and deep understanding. Take your time, experiment, and make this knowledge your own.</p>
    <p><strong>Estimated Total Time:</strong> 2.5-3.5 hours (depending on experience level and licensed features available)</p>
  </div>
</div>

<style>
.lab-instructions {
  max-width: 900px;
  margin: 0 auto;
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
  line-height: 1.6;
  color: #333;
}

.lab-instructions h2 {
  color: #1a1a1a;
  border-bottom: 3px solid #0063F7;
  padding-bottom: 10px;
  margin-top: 30px;
}

.lab-instructions h3 {
  color: #2c3e50;
  margin-top: 25px;
}

.lab-instructions h4 {
  color: #0063F7;
  margin-top: 20px;
  margin-bottom: 10px;
}

.callout {
  padding: 20px;
  margin: 20px 0;
  border-left: 5px solid;
  border-radius: 4px;
  background-color: #f8f9fa;
}

.callout-info {
  border-left-color: #0063F7;
  background-color: #e7f3ff;
}

.callout-warning {
  border-left-color: #ff9800;
  background-color: #fff3e0;
}

.callout-success {
  border-left-color: #4caf50;
  background-color: #e8f5e9;
}

.callout-primary {
  border-left-color: #00bcd4;
  background-color: #e0f7fa;
}

.callout h3 {
  margin-top: 0;
  margin-bottom: 10px;
}

.lab-modules {
  margin: 20px 0;
}

.lab-modules hr {
  margin: 25px 0;
  border: none;
  border-top: 2px solid #e0e0e0;
}

.lab-modules a {
  color: #0063F7;
  text-decoration: none;
  font-weight: 500;
}

.lab-modules a:hover {
  text-decoration: underline;
}

code {
  background-color: #f5f5f5;
  padding: 2px 6px;
  border-radius: 3px;
  font-family: 'Courier New', Courier, monospace;
  font-size: 0.9em;
  color: #e83e8c;
}

ul, ol {
  margin: 15px 0;
  padding-left: 30px;
}

li {
  margin: 8px 0;
}

a {
  color: #0063F7;
}
</style>
```
