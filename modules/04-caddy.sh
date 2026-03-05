#!/bin/bash

# Module 04: Caddy Reverse Proxy Setup

set -e
source "${SCRIPT_DIR}/lib/functions.sh"

log_info "Installing and configuring Caddy..."

# skip if disabled in configuration
if ! is_section_enabled "caddy" "$CONFIG_FILE"; then
  log_info "Caddy is disabled in config.yml, skipping"
  exit 0
fi

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
PROXY_URL=$(get_yaml_value 'reverse_proxy_url' "$CONFIG_FILE")
EMAIL=$(get_yaml_value 'email' "$CONFIG_FILE")
WILDCARD_BASE=$(get_yaml_value 'wildcard_base' "$CONFIG_FILE")
KUMA_DOMAIN=$(get_yaml_value 'kuma_domain' "$CONFIG_FILE")

cat > /etc/caddy/Caddyfile << EOF
# Caddy configuration for reverse proxy with auto-renewal
{
    email $EMAIL
}

# primary site and wildcard for all subdomains
$WILDCARD_BASE, *.$WILDCARD_BASE {
    # send requests for the Kuma hostname to the local service
    @kuma host $KUMA_DOMAIN
    reverse_proxy @kuma http://localhost:3001

    # everything else proxies to the secondary backend
    reverse_proxy $PROXY_URL {
        header_uri -Host
        header_uri +Host {host}
    }
}
EOF

# Enable and start Caddy
systemctl enable caddy
systemctl restart caddy

log_success "Caddy installation and configuration completed"
