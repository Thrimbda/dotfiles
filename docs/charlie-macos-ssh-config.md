# charlie macOS SSH Configuration for Cloudflare Zero Trust

This guide explains how to configure SSH on charlie (macOS, IP: 192.168.50.143) to work with Cloudflare Zero Trust.

## Prerequisites

1. **Fixed IP address**: Ensure router DHCP reservation maps charlie's MAC address to `192.168.50.143`
2. **User account**: Create user `siyuan.arc` for browser SSH emergency access
3. **SSH keys**: Set up SSH key authentication for user `c1`

## User Configuration

### 1. Create Browser SSH User (siyuan.arc)

Browser SSH requires a user matching your email prefix (`siyuan.arc@gmail.com` → `siyuan.arc`):

```bash
# Create the user (if not exists)
sudo dscl . -create /Users/siyuan.arc
sudo dscl . -create /Users/siyuan.arc UserShell /bin/zsh
sudo dscl . -create /Users/siyuan.arc RealName "Siyuan Arc"
sudo dscl . -create /Users/siyuan.arc UniqueID "501"  # Use an available UID
sudo dscl . -create /Users/siyuan.arc PrimaryGroupID 20  # staff group
sudo dscl . -create /Users/siyuan.arc NFSHomeDirectory /Users/siyuan.arc

# Create home directory
sudo mkdir /Users/siyuan.arc
sudo chown siyuan.arc:staff /Users/siyuan.arc

# Set password (for browser SSH testing)
sudo dscl . -passwd /Users/siyuan.arc "temporary-password-here"
```

**Note**: Browser SSH needs password authentication. Only enable temporarily for testing.

### 2. SSH Configuration File

Edit `/etc/ssh/sshd_config`:

```bash
sudo nano /etc/ssh/sshd_config
```

Add/ensure these settings:

```
# Security settings
PasswordAuthentication yes          # Enable for browser SSH testing
PermitRootLogin no
ChallengeResponseAuthentication no
UsePAM yes
X11Forwarding yes
PrintMotd no
AcceptEnv LANG LC_*

# Allow specific users
AllowUsers c1 siyuan.arc

# Key authentication
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys

# Port and listening
Port 22
ListenAddress 0.0.0.0  # Or 192.168.50.143 for local only
```

### 3. SSH Service Management

```bash
# Start SSH service (if not running)
sudo systemsetup -setremotelogin on

# Or using launchctl
sudo launchctl load -w /System/Library/LaunchDaemons/ssh.plist

# Check status
sudo launchctl list | grep ssh
sudo systemsetup -getremotelogin

# Restart SSH
sudo launchctl unload /System/Library/LaunchDaemons/ssh.plist
sudo launchctl load -w /System/Library/LaunchDaemons/ssh.plist
```

### 4. Firewall Configuration

```bash
# Enable firewall
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on

# Allow SSH
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add /usr/sbin/sshd
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --unblockapp /usr/sbin/sshd
```

Or use System Preferences:
1. System Preferences → Security & Privacy → Firewall → Turn On Firewall
2. Click Firewall Options → Add `/usr/sbin/sshd`

### 5. Test SSH Access

From atlas (Linux server):

```bash
# Test SSH with keys (user c1)
ssh c1@192.168.50.143

# Test SSH with password (user siyuan.arc, for browser SSH testing)
ssh siyuan.arc@192.168.50.143
```

## Nix Integration (Optional)

If you want to manage SSH configuration through Nix on macOS, add to `hosts/charlie/default.nix`:

```nix
{
  # SSH service configuration for macOS
  services.ssh.enable = true;
  
  # User configuration
  users.users.siyuan.arc = {
    name = "siyuan.arc";
    home = "/Users/siyuan.arc";
    shell = pkgs.zsh;
  };
  
  # SSH configuration
  launchd.user.agents.sshd = {
    serviceConfig = {
      ProgramArguments = [ "/usr/sbin/sshd" "-D" ];
      Sockets = {
        Listeners = {
          SockServiceName = "ssh";
          SockType = "stream";
          SockFamily = "IPv4";
        };
      };
      RunAtLoad = true;
      StandardErrorPath = "/var/log/sshd.log";
      StandardOutPath = "/var/log/sshd.log";
    };
  };
}
```

## Router Configuration

Ensure your router has:

1. **DHCP Reservation**:
   - charlie (macOS): MAC address → `192.168.50.143`
   - atlas (Linux): MAC address → `192.168.50.227`

2. **Firewall Rules**:
   - Allow SSH (port 22) between local devices
   - No external port forwarding needed (Cloudflare Tunnel handles this)

## Security Considerations

### Temporary Settings for Browser SSH Testing
1. Enable `PasswordAuthentication` only during initial testing
2. Test browser SSH access at `https://ssh-mac.your-domain.com`
3. After confirming browser SSH works, disable password auth:
   ```
   PasswordAuthentication no
   ```
4. Restart SSH service

### Long-term Security
1. Use SSH keys only for user `c1`
2. Keep user `siyuan.arc` password disabled when not using browser SSH
3. Monitor SSH login attempts
4. Enable macOS firewall

## Troubleshooting

### SSH Connection Issues
```bash
# Check SSH service is running
sudo launchctl list | grep ssh

# Check SSH port is listening
sudo lsof -i :22

# Check firewall
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --listapps | grep ssh

# View SSH logs
sudo log show --predicate 'process == "sshd"' --last 10m
```

### Browser SSH Issues
1. Confirm user `siyuan.arc` exists and has password set
2. Verify `PasswordAuthentication yes` in sshd_config
3. Check Cloudflare Access policy allows your email
4. Test locally first: `ssh siyuan.arc@localhost`

### Cloudflare WARP Access
1. Ensure charlie's IP is in the routed CIDR (`192.168.50.0/24`)
2. Test from external device with WARP: `ssh c1@192.168.50.143`
3. Verify tunnel routes: `cloudflared tunnel route ip list` (on atlas)

## Maintenance

### Regular Checks
- Verify SSH service is running
- Review SSH auth logs: `sudo log show --predicate 'process == "sshd"' --last 1d`
- Monitor failed login attempts
- Keep macOS and SSH software updated

### Backup SSH Configuration
```bash
# Backup SSH config
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
sudo cp ~/.ssh/authorized_keys ~/.ssh/authorized_keys.backup

# Backup user account
sudo dscl . -read /Users/siyuan.arc > ~/siyuan.arc-user-backup.txt
```

## Integration Checklist

- [ ] Router: DHCP reservation for charlie (192.168.50.143)
- [ ] Router: DHCP reservation for atlas (192.168.50.227) 
- [ ] macOS: Create user `siyuan.arc`
- [ ] macOS: Configure `/etc/ssh/sshd_config`
- [ ] macOS: Enable and test SSH service
- [ ] macOS: Configure firewall
- [ ] atlas: Run cloudflared-setup script
- [ ] atlas: Add cloudflared configuration to default.nix
- [ ] atlas: Deploy with `hey sync atlas`
- [ ] Cloudflare: Configure browser SSH applications
- [ ] External device: Install and configure WARP client
- [ ] Test: SSH from external device via WARP
- [ ] Test: Browser SSH emergency access