#!/bin/bash

# Module 05: Tailscale VPN Setup

set -e
source "${SCRIPT_DIR}/lib/functions.sh"

log_info "Installing and configuring Tailscale..."

# Add Tailscale repository
curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/noble.noarmor.gpg | sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/noble.tailscale-keyring.list | sudo tee /etc/apt/sources.list.d/tailscale.list

apt-get update
apt-get install -y tailscale

# Get Tailscale configuration
AUTH_KEY=$(grep "auth_key:" "$CONFIG_FILE" | sed 's/.*: //' | tr -d '"' | tr -d "'")
HOSTNAME=$(grep "hostname:" "$CONFIG_FILE" | sed 's/.*: //' | tr -d '"' | tr -d "'")

# Enable and start Tailscale
systemctl enable tailscaled
systemctl start tailscaled

# Login to Tailscale
if [[ -n "$AUTH_KEY" ]]; then
  log_info "Authenticating with Tailscale..."
  tailscale up --authkey="$AUTH_KEY"
else
  log_info "No auth key provided. Run 'sudo tailscale up' to authenticate"
fi

log_success "Tailscale installation and configuration completed"
