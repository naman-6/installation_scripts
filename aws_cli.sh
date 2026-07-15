#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Suppress interactive prompts during apt package management
export DEBIAN_FRONTEND=noninteractive

echo "=== Step 1: Installing Prerequisites ==="
sudo apt-get update
# Ensure curl and unzip are installed silently
sudo apt-get install -y curl unzip

echo "=== Step 2: Downloading AWS CLI v2 ==="
# Download to the /tmp directory to keep the workspace clean
curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"

echo "=== Step 3: Extracting Installer ==="
# Extract quietly (-q) to /tmp to avoid flooding the deployment logs
unzip -q /tmp/awscliv2.zip -d /tmp

echo "=== Step 4: Installing or Updating AWS CLI ==="
# The --update flag ensures this works for both fresh installs and upgrading existing installs
sudo /tmp/aws/install --update

echo "=== Step 5: Cleaning up Temporary Files ==="
# Remove the downloaded archive and extracted directory
rm -rf /tmp/awscliv2.zip /tmp/aws

echo "========================================================="
echo " AWS CLI installation complete!"
echo " Verify the installation by running:"
echo " aws --version"
echo "========================================================="
