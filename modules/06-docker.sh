#!/bin/bash

# Module 06: Docker and Uptime Kuma Setup

set -e
source "${SCRIPT_DIR}/lib/functions.sh"

log_info "Installing Docker and Uptime Kuma..."

# Install Docker dependencies
apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release

# Add Docker official GPG key
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Add Docker repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Enable and start Docker
systemctl enable docker
systemctl start docker

# Create docker-compose file for Uptime Kuma
mkdir -p /opt/uptime-kuma
cat > /opt/uptime-kuma/docker-compose.yml << 'EOF'
version: '3'
services:
  uptime-kuma:
    image: louislam/uptime-kuma:latest
    container_name: uptime-kuma
    restart: always
    ports:
      - "3001:3001"
    volumes:
      - uptime-kuma-data:/app/data
    environment:
      - PUID=1000
      - PGID=1000

volumes:
  uptime-kuma-data:
EOF

# Deploy Uptime Kuma
log_info "Starting Uptime Kuma..."
cd /opt/uptime-kuma
docker compose up -d

log_success "Docker and Uptime Kuma installation completed"
log_info "Uptime Kuma is available at http://localhost:3001"
