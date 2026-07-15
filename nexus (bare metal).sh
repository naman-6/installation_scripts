#!/bin/bash

# Exit immediately on error and suppress interactive prompts
set -e
export DEBIAN_FRONTEND=noninteractive

echo "=== Step 1: System Update & Prerequisites ==="
sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install -y wget curl tar lsb-release ca-certificates gnupg
sudo install -m 0755 -d /etc/apt/keyrings

echo "=== Step 2: Linux Kernel Limits Tuning ==="
# Nexus requires high file handle limits to prevent crashes
echo -e "nexus   -   nofile   65536\nnexus   -   nproc    4096" | sudo tee -a /etc/security/limits.conf > /dev/null

echo "=== Step 3: Installing Java 17 (Adoptium Temurin) ==="
# Removing key if exists for idempotency, then downloading
sudo rm -f /etc/apt/keyrings/adoptium.gpg
curl -fsSL https://packages.adoptium.net/artifactory/api/gpg/key/public | sudo gpg --dearmor -o /etc/apt/keyrings/adoptium.gpg --yes
echo "deb [signed-by=/etc/apt/keyrings/adoptium.gpg] https://packages.adoptium.net/artifactory/deb $(. /etc/os-release && echo "$VERSION_CODENAME") main" | sudo tee /etc/apt/sources.list.d/adoptium.list > /dev/null
sudo apt-get update
sudo apt-get install -y temurin-17-jdk

echo "=== Step 4: Downloading & Extracting Nexus ==="
# Download the latest Linux tarball
sudo wget -q -O /tmp/nexus.tar.gz https://download.sonatype.com/nexus/3/latest-unix.tar.gz

# Extract to /opt (this creates two directories: 'nexus-3.x.y' and 'sonatype-work')
sudo tar -xzf /tmp/nexus.tar.gz -C /opt/
sudo rm /tmp/nexus.tar.gz

# Dynamically find the extracted nexus folder and rename it for a clean path
NEXUS_DIR=$(find /opt -maxdepth 1 -type d -name "nexus-3*")
sudo mv "$NEXUS_DIR" /opt/nexus

echo "=== Step 5: Creating User & Setting Permissions ==="
if ! getent group nexus > /dev/null; then sudo groupadd nexus; fi
if ! getent passwd nexus > /dev/null; then sudo useradd -c "Nexus User" -d /opt/nexus -g nexus -s /bin/bash nexus; fi

# Set ownership of both the app directory and the data directory
sudo chown -R nexus:nexus /opt/nexus
sudo chown -R nexus:nexus /opt/sonatype-work

# Tell Nexus to run as the 'nexus' user
echo 'run_as_user="nexus"' | sudo tee /opt/nexus/bin/nexus.rc > /dev/null

echo "=== Step 6: Creating Systemd Service ==="
cat <<EOF | sudo tee /etc/systemd/system/nexus.service > /dev/null
[Unit]
Description=Nexus Repository Manager
After=network.target

[Service]
Type=forking
LimitNOFILE=65536
LimitNPROC=4096
User=nexus
Group=nexus
ExecStart=/opt/nexus/bin/nexus start
ExecStop=/opt/nexus/bin/nexus stop
Restart=on-abort

[Install]
WantedBy=multi-user.target
EOF

echo "=== Step 7: Starting Nexus Service ==="
sudo systemctl daemon-reload
sudo systemctl enable --now nexus

echo "========================================================="
echo " Nexus bare-metal installation complete!"
echo " Nexus is now running on port 8081."
echo " It may take 2-5 minutes for the UI to become available."
echo ""
echo " IMPORTANT: To get your initial admin password, run:"
echo " sudo cat /opt/sonatype-work/nexus3/admin.password"
echo "========================================================="
