#!/bin/bash

# Module 02: SSH Hardening

set -e
source "${SCRIPT_DIR}/lib/functions.sh"

log_info "Configuring SSH security..."

# Check if SSH hardening is enabled
if ! grep -q "ssh:" "$CONFIG_FILE" || ! grep -q "enabled: true" "$CONFIG_FILE"; then
  log_info "SSH hardening disabled in config"
  exit 0
fi

# Backup original sshd_config
if [[ ! -f /etc/ssh/sshd_config.backup ]]; then
  cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
fi

# Disable SSH password login
sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^#\?PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config

# Disable root login via SSH
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config

# Other security settings
sed -i 's/^#\?PermitEmptyPasswords.*/PermitEmptyPasswords no/' /etc/ssh/sshd_config
sed -i 's/^#\?X11Forwarding.*/X11Forwarding no/' /etc/ssh/sshd_config
sed -i 's/^#\?MaxAuthTries.*/MaxAuthTries 3/' /etc/ssh/sshd_config

# Validate SSH configuration before restarting
if sshd -t; then
  systemctl restart ssh
  log_success "SSH hardening completed"
else
  log_error "SSH configuration validation failed"
  cp /etc/ssh/sshd_config.backup /etc/ssh/sshd_config
  exit 1
fi
