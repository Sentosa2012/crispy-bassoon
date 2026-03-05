#!/bin/bash

# Module 03: Fail2ban Setup

set -e
source "${SCRIPT_DIR}/lib/functions.sh"

log_info "Installing and configuring Fail2ban..."

# Install fail2ban
apt-get install -y fail2ban

# Create fail2ban local configuration
cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 2592000
findtime = 600
maxretry = 3
destemail = root@localhost
sendername = Fail2Ban
banaction = iptables-multiport

[sshd]
enabled = true
EOF

# Create fail2ban filter if needed
if [[ ! -f /etc/fail2ban/filter.d/sshd.conf ]]; then
  cp /etc/fail2ban/filter.d/sshd.conf.orig /etc/fail2ban/filter.d/sshd.conf || true
fi

# Enable and start fail2ban
systemctl enable fail2ban
systemctl restart fail2ban

log_success "Fail2ban installation and configuration completed"
