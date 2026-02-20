#!/bin/bash
set -e

# ------------------------------
# Update & Install Docker
# ------------------------------
apt-get update -y
curl -fsSL https://get.docker.com | sh
systemctl enable docker
systemctl start docker

# ------------------------------
# Install Docker Compose
# ------------------------------
COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep tag_name | cut -d '"' -f 4)
curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" \
  -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# ------------------------------
# Install Dokploy
# ------------------------------
curl -sSL https://dokploy.com/install.sh | bash

# ------------------------------
# Install Harbor
# ------------------------------
cd /opt

HARBOR_VERSION="2.11.1"

curl -LO https://github.com/goharbor/harbor/releases/download/v${HARBOR_VERSION}/harbor-online-installer-v${HARBOR_VERSION}.tgz
tar xzf harbor-online-installer-v${HARBOR_VERSION}.tgz

cd harbor

# Create harbor.yml
cp harbor.yml.tmpl harbor.yml

# Basic config (เปลี่ยน IP/domain ตามต้องการ)
# PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
# sed -i "s/^hostname:.*/hostname: ${PUBLIC_IP}/" harbor.yml

SUB_DOMAIN=hub-domain
sed -i "s/^hostname:.*/hostname: ${SUB_DOMAIN}.de451.cloud/" harbor.yml
sed -i 's/^  port: 80/  port: 8080/' harbor.yml
sed -i '/^https:/,/^$/ s/^/#/' harbor.yml
sed -i "s|^#\? *external_url:.*|external_url: https://${SUB_DOMAIN}.de451.cloud|" harbor.yml

# install harbor
./prepare
./install.sh

sed -i '/8080:8080/d' docker-compose.yml

docker compose down
docker compose up -d

sleep 15

docker network connect dokploy-network nginx || true

# ------------------------------
# Firewall
# ------------------------------
ufw --force enable
ufw allow 22,80,443,3000/tcp
