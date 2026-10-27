#!/bin/bash
# init.sh
set -e # Exit immediately if a command exits with a non-zero status

# 1. Update system packages
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get upgrade -y

# 2. Install prerequisites
apt-get install -y ca-certificates curl gnupg git

# 3. Add Docker's official GPG key
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://docker.com | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

# 4. Set up the stable Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://docker.com \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

# 5. Cleanly install Docker Engine and Docker Compose Plugin
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 6. Enable and start Docker service
systemctl enable docker
systemctl start docker

# 7. Grant the 'ubuntu' user permissions to execute Docker commands without sudo
usermod -aG docker ubuntu

# 8. Clone repository and run docker compose
# Variable ${repo_url} is interpolated dynamically by Terraform's templatefile()
cd /home/ubuntu
git clone ${repo_url} app-repo
cd app-repo

# Run docker compose in detached mode as the root/service runner safely
# (Alternatively, 'sudo -u ubuntu docker compose up -d' if user contexts matter for your volumes)
docker compose up -d

