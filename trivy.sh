#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Suppress interactive prompts during apt package management
export DEBIAN_FRONTEND=noninteractive

echo "=== Step 1: Installing Prerequisites ==="
sudo apt-get update
# Added -y flag and included curl/ca-certificates for secure downloading
sudo apt-get install -y apt-transport-https gnupg lsb-release curl ca-certificates

echo "=== Step 2: Configuring Trivy Official GPG Key ==="
# Ensure the keyrings directory exists with correct permissions
sudo install -m 0755 -d /etc/apt/keyrings

# Remove the old key if it exists to prevent gpg from prompting to overwrite
sudo rm -f /etc/apt/keyrings/trivy-keyring.gpg

# Fetch the key and dearmor it (the modern replacement for apt-key)
curl -fsSL https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo gpg --dearmor -o /etc/apt/keyrings/trivy-keyring.gpg
sudo chmod a+r /etc/apt/keyrings/trivy-keyring.gpg

echo "=== Step 3: Adding Trivy Repository to Apt Sources ==="
# Bind the repository exclusively to the key we just downloaded
echo "deb [signed-by=/etc/apt/keyrings/trivy-keyring.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | \
  sudo tee /etc/apt/sources.list.d/trivy.list > /dev/null

echo "=== Step 4: Installing Trivy ==="
sudo apt-get update
sudo apt-get install -y trivy

echo "========================================================="
echo " Trivy installation complete!"
echo " Verify the installation by running:"
echo " trivy --version"
echo "========================================================="
