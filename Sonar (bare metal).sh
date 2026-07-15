#!/bin/bash

# Exit immediately on error and suppress interactive prompts
set -e
export DEBIAN_FRONTEND=noninteractive

echo "=== Step 1: System Update & Prerequisites ==="
sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install -y wget curl unzip gnupg lsb-release ca-certificates
sudo install -m 0755 -d /etc/apt/keyrings

echo "=== Step 2: Linux Kernel Tuning ==="
# Append limits securely
echo -e "sonarqube   -   nofile   65536\nsonarqube   -   nproc    4096" | sudo tee -a /etc/security/limits.conf > /dev/null
echo "vm.max_map_count = 262144" | sudo tee -a /etc/sysctl.conf > /dev/null
sudo sysctl -p

echo "=== Step 3: Installing PostgreSQL ==="
curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo gpg --dearmor -o /etc/apt/keyrings/postgresql.gpg --yes
echo "deb [signed-by=/etc/apt/keyrings/postgresql.gpg] http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" | sudo tee /etc/apt/sources.list.d/pgdg.list > /dev/null
sudo apt-get update
sudo apt-get install -y postgresql postgresql-contrib
sudo systemctl enable --now postgresql

echo "=== Step 4: Configuring SonarQube Database ==="
# Execute DB commands inline as the postgres user without opening an interactive shell
sudo -u postgres psql -c "CREATE USER sonar WITH ENCRYPTED PASSWORD 'sonar';"
sudo -u postgres psql -c "CREATE DATABASE sonarqube OWNER sonar;"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE sonarqube TO sonar;"

echo "=== Step 5: Installing Java 17 (Adoptium Temurin) ==="
curl -fsSL https://packages.adoptium.net/artifactory/api/gpg/key/public | sudo gpg --dearmor -o /etc/apt/keyrings/adoptium.gpg --yes
echo "deb [signed-by=/etc/apt/keyrings/adoptium.gpg] https://packages.adoptium.net/artifactory/deb $(. /etc/os-release && echo "$VERSION_CODENAME") main" | sudo tee /etc/apt/sources.list.d/adoptium.list > /dev/null
sudo apt-get update
sudo apt-get install -y temurin-17-jdk

echo "=== Step 6: Downloading & Configuring SonarQube ==="
sudo wget -q https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-9.9.0.65466.zip -O /tmp/sonarqube.zip
sudo unzip -q /tmp/sonarqube.zip -d /opt
sudo mv /opt/sonarqube-9.9.0.65466 /opt/sonarqube
rm /tmp/sonarqube.zip

# Create user and set permissions cleanly
if ! getent group sonar > /dev/null; then sudo groupadd sonar; fi
if ! getent passwd sonar > /dev/null; then sudo useradd -c "SonarQube User" -d /opt/sonarqube -g sonar -s /bin/bash sonar; fi
sudo chown -R sonar:sonar /opt/sonarqube

# Inject Database credentials into properties file
echo -e "\nsonar.jdbc.username=sonar\nsonar.jdbc.password=sonar\nsonar.jdbc.url=jdbc:postgresql://localhost/sonarqube" | sudo tee -a /opt/sonarqube/conf/sonar.properties > /dev/null

echo "=== Step 7: Creating Systemd Service ==="
# Use a heredoc to create the service file automatically
cat <<EOF | sudo tee /etc/systemd/system/sonar.service > /dev/null
[Unit]
Description=SonarQube service
After=syslog.target network.target

[Service]
Type=forking
ExecStart=/opt/sonarqube/bin/linux-x86-64/sonar.sh start
ExecStop=/opt/sonarqube/bin/linux-x86-64/sonar.sh stop
User=sonar
Group=sonar
Restart=always
LimitNOFILE=65536
LimitNPROC=4096

[Install]
WantedBy=multi-user.target
EOF

echo "=== Step 8: Starting SonarQube ==="
sudo systemctl daemon-reload
sudo systemctl enable --now sonar

echo "========================================================="
echo " SonarQube bare-metal installation complete!"
echo " It may take 1-3 minutes for the web server to boot up."
echo " Monitor the startup logs by running:"
echo " sudo tail -f /opt/sonarqube/logs/sonar.log"
echo "========================================================="
