# Lab 5: Security Testing (STO)

> **Important**: All activities in the **"Base Demo"** project

## Overview
This lab demonstrates Harness Security Testing Orchestration (STO), which integrates multiple security scanners into your CI/CD pipeline. STO provides normalized, deduplicated, and prioritized vulnerability data across all your security tools.

## Important Note

**This lab is only available with a licensed partner organization.**

If you have access to a licensed Harness partner organization, you can add the following security scanning capabilities to your pipeline:

## Security Scanning Capabilities

### Software Composition Analysis (SCA)
- **OWASP Dependency Check**: Identifies known vulnerabilities in project dependencies
- **OSV Scanner**: Checks for vulnerabilities using the Open Source Vulnerabilities database

### Container Image Scanning
- **Aqua Trivy**: Comprehensive vulnerability scanner for container images
- Scans the Docker image built in your CI pipeline

### Dynamic Application Security Testing (DAST)
- **Stage Template**: Security team-managed DAST scans
- Runs after deployment to test the running application
- Typically owned and versioned by the security team

### Static Application Security Testing (SAST)
- **Semgrep**: Static code analysis to find security vulnerabilities in source code

## What STO Provides

When enabled in a licensed partner org, STO offers:

1. **Unified Dashboard**: Single view of all security findings across multiple scanners
2. **Deduplication**: Eliminates duplicate findings from different tools
3. **Normalization**: Standardizes vulnerability data from different scanners
4. **Prioritization**: Ranks vulnerabilities by severity and exploitability
5. **Policy Enforcement**: Fail pipelines based on security policies (e.g., no critical CVEs)
6. **Exemptions**: Manage false positives and accepted risks
7. **Tracking**: Monitor vulnerability trends over time

## Integration Points in Your Pipeline

With a licensed org, you would add security scanning at these stages:

**Build Stage (SCA + SAST):**
- After the **Compile** step: Add OWASP and OSV scanners
- After the **Compile** step: Add Semgrep SAST scanner

**Build Stage (Container Scanning):**
- After the **Push to Dockerhub** step: Add Aqua Trivy scanner

**After Backend Deployment (DAST):**
- Add **DAST Scans** stage template
- Tests the live application at http://localhost:8080

## Expected Results

After scanners complete (typically 3-5 minutes), you would see:

- **Security Tests Tab**: Consolidated view of all vulnerabilities
- **Severity Breakdown**: Critical, High, Medium, Low findings
- **Affected Components**: Which dependencies or code sections have issues
- **Remediation Guidance**: How to fix identified vulnerabilities

## Next Steps

For access to STO capabilities:
1. Contact your Harness account team about partner organization licensing
2. Complete partner enablement program
3. Gain access to licensed features including STO, SSCA, and advanced policy enforcement

---
> **Note**: You can proceed with Lab 6 (Continuous Verification) which is available in the Base Demo project without additional licensing.
