#!/bin/bash

# Module 01: System Updates

set -e
source "${SCRIPT_DIR}/lib/functions.sh"

log_info "Starting system updates..."

# Update package lists
apt-get update

# Install all available updates
apt-get upgrade -y

# Install security updates
apt-get install -y unattended-upgrades apt-listchanges

# Check if auto-updates is enabled in config
if grep -q "auto_updates: true" "$CONFIG_FILE"; then
  log_info "Configuring automatic security updates..."
  
  # Enable automatic updates
  dpkg-reconfigure -plow unattended-upgrades
fi

log_success "System updates completed"
