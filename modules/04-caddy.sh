#!/bin/bash

# Module 04: Caddy Reverse Proxy Setup

set -e
source "${SCRIPT_DIR}/lib/functions.sh"

log_info "Installing and configuring Caddy..."

# Install Caddy from APT
apt-get install -y debian-keyring debian-archive-keyring apt-transport-https curl

# Add Caddy repository
curl -1sLf 'https://dl.caddy.community/api/v1/repos/caddy/caddy/releases/download?os=linux&arch=amd64' --output caddy_linux_amd64.tar.gz || {
  log_info "Using apt repository fallback for Caddy..."
  apt-get install -y caddy
}

if [[ -f caddy_linux_amd64.tar.gz ]]; then
  tar -xzf caddy_linux_amd64.tar.gz -C /usr/local/bin/
  rm caddy_linux_amd64.tar.gz
  chmod +x /usr/local/bin/caddy
fi

# Create Caddy config from template
PROXY_URL=$(grep "reverse_proxy_url:" "$CONFIG_FILE" | sed 's/.*: //' | tr -d '"' | tr -d "'")
DOMAINS=$(grep "    - " "$CONFIG_FILE" | grep -A 10 "domains:" | sed 's/.*- //' | tr '\n' ' ')
EMAIL=$(grep "email:" "$CONFIG_FILE" | sed 's/.*: //' | tr -d '"' | tr -d "'")

cat > /etc/caddy/Caddyfile << EOF
# Caddy configuration for reverse proxy with auto-renewal
{
    email $EMAIL
}

# Main reverse proxy block
EOF

for domain in $DOMAINS; do
  cat >> /etc/caddy/Caddyfile << EOF

$domain {
    reverse_proxy $PROXY_URL {
        header_uri -Host
        header_uri +Host {host}
    }
}
EOF
done

# Enable and start Caddy
systemctl enable caddy
systemctl restart caddy

log_success "Caddy installation and configuration completed"
