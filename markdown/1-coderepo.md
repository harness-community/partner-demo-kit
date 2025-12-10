# Lab 1: Code Repository Secret Scanning

> **Important**: All demo activities take place in the **"Base Demo"** project in Harness

## Overview
This lab demonstrates Harness Code Repository's secret scanning feature, which prevents sensitive data (like API tokens, passwords, and keys) from being committed to your repository.

## Prerequisites
- Terraform setup completed (creates "Base Demo" project and `partner_demo_kit` repository)
- Harness account with Code Repository module enabled

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

## Step 3: Clone the Harness Code Repository

```bash
# Clone the repository (use the URL from the Harness UI)
git clone <harness-code-repo-url>
cd partner_demo_kit

# When prompted, enter the credentials you generated in Step 2
```

## Step 4: Enable Secret Scanning

1. In Harness UI, go to **Code Repository** > **Manage Repository**
2. Click on the **Security** tab
3. Toggle **"Secret Scanning"** to **ON**
4. Click **Save**

## Step 5: Test Secret Scanning

Now let's intentionally try to commit a secret to demonstrate the blocking feature:

1. **Edit the file** `backend/entrypoint.sh`
2. **Add this line** anywhere in the file:
   ```bash
   TOKEN="02290a2a-7f5a-4836-8745-d4d797e475d0"
   ```

3. **Try to commit and push**:
   ```bash
   git add .
   git commit -m "test secret scanning"
   git push
   ```

## Expected Result

The push should be **BLOCKED** with an error message similar to:

```
! [remote rejected] main -> main (pre-receive hook declined)
error: failed to push some refs to '<repo-url>'
```

The output will indicate that a **Generic High Entropy Secret** was detected.

## Key Takeaways

- **Harness Code Repository** provides security features to protect your code
- **Secret scanning** prevents secrets from being pushed to repositories
- This is **proactive security** - blocking secrets before they enter your codebase
- No waiting for secrets to be committed - prevention happens at push time

## Why This Matters

Traditional secret detection tools scan after commits are made. Harness Code blocks secrets **before** they enter your repository, providing:
- Earlier detection in the development cycle
- Reduced risk of exposed credentials
- Compliance with security best practices
- Protection against accidental credential leaks

## Clean Up

Remove the test secret from your local file:

```bash
# Remove the TOKEN line from backend/entrypoint.sh
git checkout backend/entrypoint.sh
```

---

**Next**: Proceed to [Lab 2: CI Pipeline Setup](2-build.md)
