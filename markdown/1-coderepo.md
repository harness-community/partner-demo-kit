# Lab 1: Code Repository Secret Scanning

> **Important**: All demo activities take place in the **"Base Demo"** project in Harness

## Overview
This lab demonstrates Harness Code Repository's secret scanning feature, which prevents sensitive data (like API tokens, passwords, and keys) from being committed to your repository.

## Prerequisites
- Terraform setup completed (creates "Base Demo" project and `partner_demo_kit` repository)
- Harness account with Code Repository module enabled
- Git client installed locally

## Step 1: Navigate to Harness Code Repository

1. Log in to your Harness account at [app.harness.io](https://app.harness.io)
2. Select the **"Base Demo"** project
3. Click on **Code Repository** module in the left navigation

## Step 2: Generate Clone Credentials

The `partner_demo_kit` repository was created by Terraform. You need credentials to clone it:

1. Click on the **"partner_demo_kit"** repository
2. Click **"Clone"** button in the top right
3. Click **"+Generate Clone Credential"**
4. **Save the generated username and token** - you'll need these in the next step

> **Tip**: Consider using [Git Credential Manager](https://github.com/git-ecosystem/git-credential-manager) to securely store and manage your Git credentials. It provides a better experience than manually entering credentials each time.
>
> Install Git Credential Manager:
> - **macOS**: `brew install --cask git-credential-manager`
> - **Windows**: Download from GitHub releases
> - **Linux**: Follow instructions on the GCM GitHub page

## Step 3: Clone the Harness Code Repository

```bash
# Clone the repository (use the URL from the Harness UI)
git clone <harness-code-repo-url>
cd partner_demo_kit

# When prompted, enter the credentials you generated in Step 2
# Username: <generated-username>
# Password: <generated-token>
```

> **Note**: If using Git Credential Manager, it will securely store these credentials for future use.

## Step 4: Enable Secret Scanning

1. In Harness UI, go to **Code Repository** > **Manage Repository**
2. Click on the **Security** tab
3. Toggle **"Secret Scanning"** to **ON**
4. Click **Save**

> **What Secret Scanning Detects**:
> - API keys and tokens
> - Passwords and credentials
> - Private keys and certificates
> - High-entropy strings that look like secrets
> - Cloud provider credentials (AWS, Azure, GCP)

## Step 5: Test Secret Scanning

Now let's intentionally try to commit a secret to demonstrate the blocking feature:

1. **Edit the file** `backend/entrypoint.sh`
2. **Add this line** anywhere in the file:
   ```bash
   TOKEN="02290a2a-7f5a-4836-8745-d4d797e475d0"
   ```

3. **Stage, commit, and push your changes**:
   ```bash
   # Stage the modified file
   git add backend/entrypoint.sh

   # Create a commit with your changes
   git commit -m "test secret scanning"

   # Push to the remote repository
   git push origin main
   ```

> **Understanding Git Commands**:
> - `git add` - Stages files for commit (adds them to the "staging area")
> - `git commit` - Creates a snapshot of your staged changes with a message
> - `git push` - Uploads your local commits to the remote repository
>
> These three commands form the core Git workflow for sharing code changes.

## Expected Result

The push should be **BLOCKED** with an error message similar to:

```
remote:
remote: ===================================================================
remote: Secret Scanning: BLOCKED
remote: ===================================================================
remote: A secret has been detected in your commit.
remote:
remote: File: backend/entrypoint.sh
remote: Secret Type: Generic High Entropy Secret
remote:
remote: Please remove the secret and try again.
remote: ===================================================================
! [remote rejected] main -> main (pre-receive hook declined)
error: failed to push some refs to '<repo-url>'
```

The output will indicate that a **Generic High Entropy Secret** was detected.

> **This is Proactive Security in Action!**
> The secret was blocked BEFORE it entered the repository, preventing it from ever appearing in the Git history.

## Key Takeaways

- **Harness Code Repository** provides security features to protect your code
- **Secret scanning** prevents secrets from being pushed to repositories
- This is **proactive security** - blocking secrets before they enter your codebase
- No waiting for secrets to be committed - prevention happens at push time
- The standard Git workflow (`add`, `commit`, `push`) is enforced with security checks

## Why This Matters

Traditional secret detection tools scan after commits are made. Harness Code blocks secrets **before** they enter your repository, providing:
- Earlier detection in the development cycle
- Reduced risk of exposed credentials
- Compliance with security best practices
- Protection against accidental credential leaks
- No need to rewrite Git history to remove secrets

## Clean Up

Remove the test secret from your local file:

```bash
# Discard changes to the file (restore to last committed version)
git checkout backend/entrypoint.sh

# Verify the file is clean
git status
```

> **Note**: Since the push was blocked, the secret never entered the repository. You only need to clean up your local working directory.

---

**Next**: Proceed to [Lab 2: CI Pipeline Setup](2-build.md)
