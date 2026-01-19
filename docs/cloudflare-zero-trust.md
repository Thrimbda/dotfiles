# Cloudflare Zero Trust with Nix

This guide explains how to integrate Cloudflare Zero Trust Tunnel into your Nix-managed dotfiles for secure private network access.

## Overview

The setup provides:
- **WARP private routing**: Access home network (e.g., `192.168.50.0/24`) from external devices with WARP client
- **Browser SSH emergency access**: SSH via browser when WARP is not installed
- **Nix-managed service**: Declarative configuration with secret management via agenix

## Architecture

```
Home Network (192.168.50.0/24)
├── atlas (Linux server, 192.168.50.227) runs cloudflared
├── charlie (macOS, 192.168.50.143) accessible via SSH
└── Cloudflare Tunnel
    ├── WARP clients (external devices with Zero Trust enrollment)
    └── Browser SSH (emergency access via public hostnames)
```

## Prerequisites

1. **Domain hosted on Cloudflare** (NS records pointing to Cloudflare)
2. **Cloudflare Zero Trust organization** (free tier: <50 users)
3. **NixOS or Darwin system** with this dotfiles repository
4. **Fixed IPs** for home devices (DHCP reservation on router)

## Module: `modules/services/cloudflared.nix`

The Nix module provides:

### Options
- `enable`: Enable the service
- `tunnelId`: Cloudflare Tunnel ID (from `cloudflared tunnel create`)
- `credentialsFile`: Age-encrypted credentials file
- `warpRouting.enabled`: Enable WARP private routing
- `warpRouting.cidrs`: List of CIDRs to route (e.g., `["192.168.50.0/24"]`)
- `config`: Additional YAML configuration attributes

### Features
- **Age secret management**: Encrypted credentials stored in `secrets/`
- **Systemd service**: Automatic start, restart on failure
- **Config file**: Generated `~/.cloudflared/config.yml`
- **WARP routes**: Automatic route addition (if enabled)

## Setup Procedure

### Step 1: Initial Tunnel Setup

Run the setup script:

```bash
cd /Users/c1/Work/dotfiles
./bin/cloudflared-setup --host <hostname> --cidr 192.168.50.0/24
```

Or manually:

1. **Install and login**:
   ```bash
   # Install cloudflared
   nix-env -iA nixpkgs.cloudflared
   
   # Login (opens browser)
   cloudflared tunnel login
   ```

2. **Create tunnel**:
   ```bash
   cloudflared tunnel create home
   # Note the tunnel ID shown (e.g., "abcd1234-...")
   ```

3. **Encrypt credentials**:
   ```bash
   # Find credentials file
   ls ~/.cloudflared/*.json
   
   # Encrypt with agenix
   agenix -e hosts/<hostname>/secrets/cloudflared-credentials.age \
          -i /etc/ssh/host_ed25519 \
          ~/.cloudflared/<tunnel-id>.json
   ```

### Step 2: Host Configuration

Add to your host's `default.nix` (e.g., `hosts/ramen/default.nix`):

```nix
{
  modules.services.cloudflared = {
    enable = true;
    tunnelId = "abcd1234-...";  # Your tunnel ID
    credentialsFile = ./secrets/cloudflared-credentials.age;
    warpRouting = {
      enabled = true;
      cidrs = [ "192.168.50.0/24" ];
    };
    config = {
      # Optional additional config
      # ingress = [ ... ];
    };
  };
}
```

### Step 3: Deploy

```bash
# Build and switch
hey sync <hostname>

# Check service status
sudo systemctl status cloudflared
journalctl -u cloudflared -f

# Verify tunnel
cloudflared tunnel list
cloudflared tunnel route ip list
```

## External Device Configuration

### WARP Client (Primary Access)

1. Install Cloudflare WARP (1.1.1.1) on external device
2. Choose "Use team/organization (Zero Trust)"
3. Enter your team name (from Cloudflare Zero Trust)
4. Login with your account
5. Test connectivity:
   ```bash
   ssh c1@192.168.50.227  # Linux server (atlas)
   ssh c1@192.168.50.143  # Mac (charlie)
   ```

### Browser SSH (Emergency Access)

1. **Cloudflare Dashboard** → Zero Trust → Access → Applications
 2. **Add Self-hosted application**:
    - Name: SSH Linux (atlas)
    - Domain: `ssh-linux.your-domain.com`
    - Service: SSH → `192.168.50.227:22`  # atlas (Linux)
    - Browser rendering: SSH
 3. **Repeat for Mac**:
    - Name: SSH Mac (charlie)
    - Domain: `ssh-mac.your-domain.com`
    - Service: SSH → `192.168.50.143:22`  # charlie (macOS)
    - Browser rendering: SSH
4. **Access URLs**:
   - `https://ssh-linux.your-domain.com`
   - `https://ssh-mac.your-domain.com`

**Note**: Browser SSH requires server user matching email prefix (e.g., `siyuan.arc@gmail.com` → user `siyuan.arc`).

## Security Considerations

### SSH Configuration
Ensure SSH server on Linux/Mac has:
```bash
# /etc/ssh/sshd_config
PasswordAuthentication no
PermitRootLogin no
PubkeyAuthentication yes
AllowUsers c1 siyuan.arc  # Browser SSH user
```

### Cloudflare Access Policies
- Enable MFA for all applications
- Restrict access to your email only
- Set session duration (e.g., 24h)
- Enable audit logging

### Firewall Rules
On Linux server:
```bash
sudo ufw allow from 192.168.50.0/24 to any port 22
sudo ufw default deny incoming
```

## Troubleshooting

### Service Issues
```bash
# Check logs
journalctl -u cloudflared -f

# Verify tunnel connectivity
cloudflared tunnel list
cloudflared tunnel info <tunnel-id>

# Test WARP routing
cloudflared tunnel route ip list
```

### WARP Connection Issues
1. Verify device is enrolled in Zero Trust organization
2. Check WARP client connection status
3. Ensure home firewall allows ICMP/SSH
4. Test with `ping 192.168.50.227`  # atlas (Linux server)

### Browser SSH Issues
1. Confirm server user exists (email prefix)
2. Temporarily enable password authentication for testing
3. Check Cloudflare Access policy configuration
4. Verify DNS records propagate

## Integration with Existing Scripts

The TypeScript deployment scripts in `/Users/c1/Work/edge` can be used for initial setup, but Nix manages the ongoing service. Use the scripts for:

1. **Initial tunnel creation**: `npm run deploy:setup`
2. **WARP routing**: `npm run deploy:configure`
3. **Browser SSH setup**: `npm run deploy:browser-ssh`

Then transition to Nix for persistent management.

## Maintenance

### Regular Checks
- Monitor cloudflared service status
- Review Cloudflare Access logs
- Update SSH keys periodically
- Keep NixOS/dotfiles updated

### Backup
```bash
# Backup important files
tar -czf cloudflare-backup.tar.gz \
  ~/.cloudflared/ \
  /etc/systemd/system/cloudflared.service \
  hosts/<hostname>/secrets/cloudflared-credentials.age
```

## References

- [Cloudflare Zero Trust Docs](https://developers.cloudflare.com/cloudflare-one/)
- [Cloudflare Tunnel Local Management](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/tunnel-guide/local/)
- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Age Encryption](https://github.com/FiloSottile/age)

## Support

For issues with the Nix module:
1. Check service logs: `journalctl -u cloudflared`
2. Review host configuration syntax
3. Ensure age secrets are properly encrypted
4. Verify tunnel ID and credentials

For Cloudflare issues:
1. Check Zero Trust dashboard configuration
2. Verify domain DNS settings
3. Review Access policy logs