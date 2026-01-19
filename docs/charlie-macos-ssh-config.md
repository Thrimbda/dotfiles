# charlie macOS SSH 配置指南（Cloudflare Zero Trust）

本文档介绍如何在 charlie（macOS，IP: 192.168.50.143）上配置 SSH 以与 Cloudflare Zero Trust 配合工作。

## 先决条件

1. **固定 IP 地址**：确保路由器 DHCP 保留将 charlie 的 MAC 地址映射到 `192.168.50.143`
2. **Cloudflare 隧道**：为 charlie 创建独立的 cloudflared tunnel 与凭证
3. **用户账户**：创建用户 `siyuan.arc` 用于浏览器 SSH 紧急访问
4. **SSH 密钥**：为用户 `c1` 设置 SSH 密钥认证

## 用户配置

### 1. 创建浏览器 SSH 用户 (siyuan.arc)

浏览器 SSH 需要一个与您邮箱前缀匹配的用户（`siyuan.arc@gmail.com` → `siyuan.arc`）：

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

**注意**：浏览器 SSH 需要密码认证。仅临时启用用于测试。

### 2. SSH 配置文件

编辑 `/etc/ssh/sshd_config`：

```bash
sudo nano /etc/ssh/sshd_config
```

添加/确保以下设置：

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

### 3. SSH 服务管理

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

### 4. 防火墙配置

或使用系统偏好设置：
1. 系统偏好设置 → 安全性与隐私 → 防火墙 → 打开防火墙
2. 点击防火墙选项 → 添加 `/usr/sbin/sshd`

### 5. 测试 SSH 访问

从 atlas (Linux 服务器) 测试：

```bash
# Test SSH with keys (user c1)
ssh c1@192.168.50.143

# Test SSH with password (user siyuan.arc, for browser SSH testing)
ssh siyuan.arc@192.168.50.143
```

### 6. cloudflared（独立隧道）

在 charlie 上为独立隧道启用 cloudflared：

```nix
modules.services.cloudflared = {
  enable = true;
  # tunnelId = "charlie-tunnel-id";
  # credentialsFile = ./secrets/cloudflared-credentials.age;
  warpRouting = {
    enabled = true;
    cidrs = [ "192.168.50.0/24" ];
  };
  config = {
    tunnelName = "home-charlie";
  };
};
```

## Nix 集成（可选）

如果要在 macOS 上通过 Nix 管理 SSH 配置，添加到 `hosts/charlie/default.nix`：

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

## 路由器配置

确保您的路由器有以下配置：

1. **DHCP 保留**：
   - charlie (macOS): MAC 地址 → `192.168.50.143`
   - atlas (Linux): MAC 地址 → `192.168.50.227`

2. **防火墙规则**：
   - 允许本地设备之间的 SSH（端口 22）
   - 不需要外部端口转发（Cloudflare Tunnel 处理此功能）

## 安全注意事项

### 浏览器 SSH 测试的临时设置
1. 仅在初始测试期间启用 `PasswordAuthentication`
2. 在 `https://ssh-mac.your-domain.com` 测试浏览器 SSH 访问
3. 确认浏览器 SSH 工作后，禁用密码认证：
   ```
   PasswordAuthentication no
   ```
4. 重启 SSH 服务

### 长期安全
1. 仅对用户 `c1` 使用 SSH 密钥
2. 不使用浏览器 SSH 时保持用户 `siyuan.arc` 密码禁用
3. 监控 SSH 登录尝试
4. 启用 macOS 防火墙

## 故障排除

### SSH 连接问题
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

### 浏览器 SSH 问题
1. 确认用户 `siyuan.arc` 存在且已设置密码
2. 验证 sshd_config 中 `PasswordAuthentication yes`
3. 检查 Cloudflare Access 策略允许您的邮箱
4. 首先本地测试：`ssh siyuan.arc@localhost`

### Cloudflare WARP 访问
1. 确保 charlie 的 IP 在路由的 CIDR 中（`192.168.50.0/24`）
2. 从带有 WARP 的外部设备测试：`ssh c1@192.168.50.143`
3. 验证隧道路由：`cloudflared tunnel route ip list`（在 charlie 或 atlas 上）

## 维护

### 常规检查
- 验证 SSH 服务正在运行
- 审查 SSH 认证日志：`sudo log show --predicate 'process == "sshd"' --last 1d`
- 监控失败的登录尝试
- 保持 macOS 和 SSH 软件更新

### SSH 配置备份
```bash
# Backup SSH config
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
sudo cp ~/.ssh/authorized_keys ~/.ssh/authorized_keys.backup

# Backup user account
sudo dscl . -read /Users/siyuan.arc > ~/siyuan.arc-user-backup.txt
```

## 集成清单

- [ ] 路由器：为 charlie 配置 DHCP 保留 (192.168.50.143)
- [ ] 路由器：为 atlas 配置 DHCP 保留 (192.168.50.227) 
- [ ] macOS：创建用户 `siyuan.arc`
- [ ] macOS：配置 `/etc/ssh/sshd_config`
- [ ] macOS：启用并测试 SSH 服务
- [ ] macOS：配置防火墙
- [ ] atlas：运行 cloudflared-setup 脚本
- [ ] atlas：添加 cloudflared 配置到 default.nix
- [ ] atlas：使用 `sudo nixos-rebuild switch --flake .#atlas` 部署
- [ ] charlie：使用 `sudo darwin-rebuild switch --flake .#charlie` 部署

- [ ] Cloudflare：配置浏览器 SSH 应用
- [ ] 外部设备：安装并配置 WARP 客户端
- [ ] 测试：通过 WARP 从外部设备 SSH
- [ ] 测试：浏览器 SSH 紧急访问
