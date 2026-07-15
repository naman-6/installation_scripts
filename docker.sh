#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Suppress interactive prompts during apt package management
export DEBIAN_FRONTEND=noninteractive

echo "=== Step 1: Removing conflicting or legacy container packages ==="
sudo apt-get remove -y docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc || true

echo "=== Step 2: Updating package database and installing utilities ==="
sudo apt-get update
sudo apt-get install -y ca-certificates curl

echo "=== Step 3: Configuring Docker Official GPG Key ==="
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo "=== Step 4: Adding Docker Repository to Apt Sources ==="
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "=== Step 5: Installing Latest Docker Engine Components ==="
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "=== Step 6: Managing Permissions & Non-Root Execution ==="
# Add current user to the docker group
sudo usermod -aG docker $USER

# Correctly configure system socket ownership and permissions safely
if [ -S /var/run/docker.sock ]; then
    sudo chown root:docker /var/run/docker.sock
    sudo chmod 660 /var/run/docker.sock
fi

echo "========================================================="
echo " Docker installation complete!"
echo " IMPORTANT: To apply the group changes without logging out,"
echo " please run the following command in your terminal:"
echo " newgrp docker"
echo "========================================================="
