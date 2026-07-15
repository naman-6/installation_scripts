#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Suppress interactive prompts during apt package management
export DEBIAN_FRONTEND=noninteractive

echo "=== Step 1: Installing Prerequisites ==="
sudo apt-get update
# Ensure base utilities are present for downloading and parsing OS releases
sudo apt-get install -y curl gnupg lsb-release ca-certificates

echo "=== Step 2: Configuring HashiCorp Official GPG Key ==="
# Ensure the keyrings directory exists with correct permissions
sudo install -m 0755 -d /etc/apt/keyrings

# Remove the old key if it exists to prevent gpg from prompting to overwrite
sudo rm -f /etc/apt/keyrings/hashicorp-archive-keyring.gpg

# Fetch the key and dearmor it securely
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/hashicorp-archive-keyring.gpg
sudo chmod a+r /etc/apt/keyrings/hashicorp-archive-keyring.gpg

echo "=== Step 3: Adding HashiCorp Repository to Apt Sources ==="
# Bind the repository to the keyring and dynamically fetch the OS codename
echo "deb [signed-by=/etc/apt/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
  sudo tee /etc/apt/sources.list.d/hashicorp.list > /dev/null

echo "=== Step 4: Installing Terraform ==="
sudo apt-get update
sudo apt-get install -y terraform

echo "========================================================="
echo " Terraform installation complete!"
echo " Verify the installation by running:"
echo " terraform --version"
echo "========================================================="
