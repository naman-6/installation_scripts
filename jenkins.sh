#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Suppress interactive prompts during apt package management
export DEBIAN_FRONTEND=noninteractive

echo "=== Step 1: Installing Java (Jenkins Dependency) ==="
sudo apt-get update
# Added the -y flag here to prevent the script from hanging
sudo apt-get install -y fontconfig openjdk-21-jre

# Display Java version for verification in the logs
java -version

echo "=== Step 2: Configuring Jenkins Official GPG Key ==="
# Ensure the keyrings directory exists with correct permissions
sudo install -m 0755 -d /etc/apt/keyrings

# Fetch the key using curl for consistency with standard modern practices
sudo curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key -o /etc/apt/keyrings/jenkins-keyring.asc
sudo chmod a+r /etc/apt/keyrings/jenkins-keyring.asc

echo "=== Step 3: Adding Jenkins Repository to Apt Sources ==="
echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | \
  sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

echo "=== Step 4: Installing Jenkins ==="
sudo apt-get update
sudo apt-get install -y jenkins

echo "=== Step 5: Enabling and Starting Jenkins Service ==="
# Ensure Jenkins starts automatically on system boot and start it now
sudo systemctl enable jenkins
sudo systemctl start jenkins

echo "========================================================="
echo " Jenkins installation complete!"
echo " Jenkins is now running and accessible on port 8080."
echo ""
echo " IMPORTANT: To unlock your Jenkins dashboard, run:"
echo " sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
echo "========================================================="
