FROM python:3.11-slim

# Install pytest and any other test dependencies
# This creates a lightweight test image for CI pipelines
RUN pip install --no-cache-dir pytest>=7.4.0

# Set working directory to match Harness CI workspace
WORKDIR /harness

# This image is used in Harness Test Intelligence steps
# Tag: dockerhubaccountid/harness-demo:test-latest
# Usage: Replaces need for preCommand to install pytest on every run
#
# IMPORTANT: Build for amd64 (Harness Cloud architecture)
# Apple Silicon users: docker buildx build --platform linux/amd64 -t dockerhubaccountid/harness-demo:test-latest --push .
# Intel/AMD users:     docker build -t dockerhubaccountid/harness-demo:test-latest .
CMD ["pytest"]
