# Ubuntu 24.04 LTS Server Setup Script

A comprehensive, modular server setup script for Ubuntu 24.04 LTS that automates deployment and hardening of production servers.

## Features

- **System Updates**: Install all available security and system updates with optional auto-update configuration
- **SSH Hardening**: Disable password login, disable root login, and configure security best practices
- **Fail2ban Protection**: Configure with permanent banning (3 failed attempts = 30-day ban)
- **Caddy Reverse Proxy**: TLS terminating reverse proxy with automatic certificate renewal and geoblocking
- **Tailscale VPN**: Secure mesh VPN integration for remote management
- **Docker**: Container runtime with Docker Compose for application deployment
- **Uptime Kuma**: Monitoring and status page dashboard

## Requirements

- Ubuntu 24.04 LTS server (fresh installation recommended)
- Root or sudo access
- Internet connectivity for package downloads
- Valid email address for Let's Encrypt certificates (Caddy)

## Installation

### 1. Clone or Download

```bash
cd ~/Documents
git clone <repository-url> Copilot\ Script
cd Copilot\ Script
```

### 2. Configure

Edit `config.yml` with your settings:

```bash
nano config.yml
```

**Key configuration sections:**

- **Caddy**: Set your domain names, backend proxy URL, and email
- **Tailscale**: Add your auth key for automatic connection (optional)
- **Docker/Uptime Kuma**: Port settings and basic configuration

### 3. Run Setup

```bash
sudo ./setup.sh -c config.yml
```

Or with custom config path:

```bash
sudo ./setup.sh -c /path/to/config.yml
```

## Configuration

### config.yml Structure

```yaml
# System updates
updates:
  enabled: true
  auto_updates: true

# SSH hardening
ssh:
  enabled: true
  disable_password_login: true
  disable_root_login: true
  port: 22

# Fail2ban protection
fail2ban:
  enabled: true
  max_retry: 3              # Attempts before banning
  bantime: 2592000          # 30 days in seconds
  findtime: 600             # 10-minute window
  destemail: root@localhost

# Caddy reverse proxy
caddy:
  enabled: true
  reverse_proxy_url: http://localhost:3000  # Backend server
  domains:
    - example.com
    - www.example.com
  email: admin@example.com
  geoblocking: true
  blocked_countries: []     # ISO country codes
  allowed_countries: []     # Whitelist mode if set

# Tailscale VPN
tailscale:
  enabled: true
  auth_key: ""              # Get from tailscale.com/admin
  hostname: ""              # Custom device name

# Docker
docker:
  enabled: true
  install_compose: true

# Uptime Kuma monitoring
uptime_kuma:
  enabled: true
  port: 3001
```

## Module Breakdown

### Module 01: System Updates (`modules/01-updates.sh`)
- Updates package lists
- Installs all available updates and security patches
- Optionally configures automatic security updates via `unattended-upgrades`

### Module 02: SSH Hardening (`modules/02-ssh.sh`)
- Disables password-based SSH authentication
- Disables root SSH login
- Configures additional security settings (X11 forwarding, max auth attempts)
- Creates backup of original sshd_config

### Module 03: Fail2ban (`modules/03-fail2ban.sh`)
- Installs fail2ban from APT repositories
- Configures for SSH protection
- Sets permanent banning: 3 failed attempts → 30-day ban
- Auto-starts on system boot

### Module 04: Caddy Reverse Proxy (`modules/04-caddy.sh`)
- Installs Caddy from official sources
- Generates Caddyfile for configured domains
- Automatic TLS certificate provisioning via Let's Encrypt
- Auto-renewal of certificates (built-in to Caddy)
- Reverse proxy forwarding to backend service

### Module 05: Tailscale VPN (`modules/05-tailscale.sh`)
- Installs Tailscale from official repository
- Configures secure mesh VPN
- Auto-login with auth key if provided
- Enables secure remote access to server

### Module 06: Docker & Uptime Kuma (`modules/06-docker.sh`)
- Installs Docker Engine from official sources (no snaps)
- Installs Docker Compose plugin
- Deploys Uptime Kuma monitoring container
- Uptime Kuma available at `http://localhost:3001`

## Usage Examples

### Basic Setup (All Defaults)

```bash
sudo ./setup.sh
```

### Custom Configuration

Edit config.yml first:

```bash
# Update your settings
nano config.yml

# Copy to secured location
sudo cp config.yml /etc/server-setup/config.yml

# Run with custom config
sudo ./setup.sh -c /etc/server-setup/config.yml
```

### Enable Specific Modules

In `config.yml`, set `enabled: false` for modules you don't want:

```yaml
tailscale:
  enabled: false  # Skip Tailscale installation
```

## Security Considerations

1. **SSH Keys Required**: After disabling password login, ensure you have SSH key access before running
2. **Fail2ban Bans**: With default config, 3 failed SSH attempts result in 30-day ban (check IP whitelist)
3. **Caddy Certificates**: Valid email required for Let's Encrypt
4. **Firewall**: Configure firewall rules separately if needed
5. **Tailscale Auth**: Keep auth keys secure - consider rotating after initial setup

## Troubleshooting

### SSH Locked Out

If you're locked out after SSH hardening:

```bash
# Access via console or secondary terminal
sudo nano /etc/ssh/sshd_config   # Reconfigure if needed
sudo systemctl restart sshd
```

### Caddy Certificate Issues

```bash
# Check Caddy status
systemctl status caddy

# View Caddy logs
journalctl -u caddy -f

# Manual certificate renewal
caddy reload
```

### Fail2ban Unbanning

```bash
# Check banned IPs
sudo fail2ban-client status sshd

# Unban specific IP
sudo fail2ban-client set sshd unbanip 192.168.1.100
```

### Docker/Uptime Kuma Access

```bash
# Check container status
docker ps

# View Uptime Kuma logs
docker logs uptime-kuma

# Access at: http://server-ip:3001
```

## Firewall Rules (Optional)

If you need to set up firewall rules:

```bash
# Allow SSH
sudo ufw allow 22/tcp

# Allow HTTP
sudo ufw allow 80/tcp

# Allow HTTPS
sudo ufw allow 443/tcp

# Allow Uptime Kuma (if external access needed)
sudo ufw allow 3001/tcp

# Allow Tailscale (typically auto-managed)
sudo ufw allow in on tailscale0

# Enable firewall
sudo ufw enable
```

## Backup & Recovery

When running this script for the first time, it creates backups:

- **SSH Config**: `/etc/ssh/sshd_config.backup`
- **Docker Volumes**: Named volumes persisted in Docker storage
- **Uptime Kuma Data**: `/var/lib/docker/volumes/`

## Advanced Configuration

### Geoblocking with Caddy

To enable geoblocking, uncomment the geoblocking section in generated Caddyfile:

```caddyfile
@blocked_countries {
    remote_ip 1.2.3.4/32 5.6.7.8/32
}
respond @blocked_countries 403
```

### Custom Caddy Configuration

Edit `/etc/caddy/Caddyfile` directly for advanced settings like:
- Custom headers
- Static file caching
- Rate limiting
- Custom error pages
- Multiple server blocks

Reload Caddy after changes:

```bash
sudo caddy reload
```

### Uptime Kuma Advanced Setup

Once Uptime Kuma is running:

1. Access at `http://server-ip:3001`
2. Create monitors for your services
3. Set up notifications (Discord, Slack, Email, etc.)
4. customize status page appearance
5. Configure backup and export settings

## Support & Logs

### View Script Logs

```bash
# Journalctl for all system services
journalctl -u fail2ban -f
journalctl -u sshd -f
journalctl -u caddy -f
journalctl -u docker -f
```

### Module Logs

Each module runs through setup.sh which provides colored output. For troubleshooting:

```bash
# Re-run specific module with output
bash ./modules/04-caddy.sh
```

## License

This script is provided as-is for Ubuntu 24.04 LTS server setup.

## Contributing

To contribute improvements:

1. Test changes in a virtual environment
2. Ensure compatibility with Ubuntu 24.04 LTS
3. Keep modules focused and reusable
4. Update config.yml defaults as needed

## Disclaimer

- Test in a staging environment first
- Always maintain backups before running server automation
- This script makes significant security changes - review carefully before deployment
- Ensure SSH key access before disabling password login
