# Cloudflare Zero Trust 与 Nix 集成指南

本文档介绍如何将 Cloudflare Zero Trust Tunnel 集成到 Nix 管理的 dotfiles 中，实现安全的私有网络访问。

## 概述

该方案提供：
- **WARP 私有路由**：外部设备通过 WARP 客户端访问家庭网络（例如 `192.168.50.0/24`）
- **浏览器 SSH 紧急访问**：当 WARP 未安装时通过浏览器进行 SSH
- **Nix 管理服务**：通过 agenix 进行秘密管理的声明式配置

## 架构

```
家庭网络 (192.168.50.0/24)
├── atlas (Linux 服务器, 192.168.50.227) 运行 cloudflared
├── charlie (macOS, 192.168.50.143) 运行 cloudflared
└── Cloudflare Zero Trust
    ├── WARP 客户端（已注册 Zero Trust 的外部设备）
    └── 浏览器 SSH（通过公开主机名的紧急访问）
```

## 先决条件

1. **域名托管在 Cloudflare**（NS 记录指向 Cloudflare）
2. **Cloudflare Zero Trust 组织**（免费版：<50 用户）
3. **NixOS 或 Darwin 系统**，包含此 dotfiles 仓库
4. **家庭设备的固定 IP**（路由器上的 DHCP 保留）

## 模块: `modules/services/cloudflared.nix`

该 Nix 模块提供：

### 选项
- `enable`: 启用服务
- `tunnelId`: Cloudflare 隧道 ID（来自 `cloudflared tunnel create`）
- `credentialsFile`: Age 加密的凭证文件
- `warpRouting.enabled`: 启用 WARP 私有路由
- `warpRouting.cidrs`: 要路由的 CIDR 列表（例如 `["192.168.50.0/24"]`）
- `config`: 额外的 YAML 配置属性

### 特性
- **Age 秘密管理**：加密凭证存储在 `secrets/` 目录
- **Systemd 服务**：自动启动，失败时重启
- **配置文件**：生成 `~/.cloudflared/config.yml`
- **WARP 路由**：自动添加路由（如果启用）

## 设置流程

### 步骤 1: 初始隧道设置

为 atlas 和 charlie 分别创建隧道：

```bash
cd /Users/c1/Work/dotfiles
./bin/cloudflared-setup --host atlas --cidr 192.168.50.0/24
./bin/cloudflared-setup --host charlie --cidr 192.168.50.0/24
```

或手动操作：

1. **安装并登录**：
   ```bash
   # 安装 cloudflared
   nix-env -iA nixpkgs.cloudflared
   
   # 登录（打开浏览器）
   cloudflared tunnel login
   ```

2. **创建隧道**（每台主机各一个）：
   ```bash
   cloudflared tunnel create home-atlas
   cloudflared tunnel create home-charlie
   # 记录显示的隧道 ID（例如 "abcd1234-...")
   ```


3. **加密凭证**（每台主机各一份）：
   ```bash
   # 查找凭证文件
   ls ~/.cloudflared/*.json

   # 使用 agenix 加密
   agenix -e hosts/atlas/secrets/cloudflared-credentials.age \
          -i /etc/ssh/host_ed25519 \
          ~/.cloudflared/<atlas-tunnel-id>.json

   agenix -e hosts/charlie/secrets/cloudflared-credentials.age \
          -i /etc/ssh/host_ed25519 \
          ~/.cloudflared/<charlie-tunnel-id>.json
   ```

### 步骤 2: 主机配置

为 atlas 与 charlie 分别添加配置：

```nix
{
  modules.services.cloudflared = {
    enable = true;
    tunnelId = "atlas-tunnel-id";
    credentialsFile = ./secrets/cloudflared-credentials.age;
    warpRouting = {
      enabled = true;
      cidrs = [ "192.168.50.0/24" ];
    };
    config = {
      tunnelName = "home-atlas";
    };
  };
}
```

```nix
{
  modules.services.cloudflared = {
    enable = true;
    tunnelId = "charlie-tunnel-id";
    credentialsFile = ./secrets/cloudflared-credentials.age;
    warpRouting = {
      enabled = true;
      cidrs = [ "192.168.50.0/24" ];
    };
    config = {
      tunnelName = "home-charlie";
    };
  };
}
```

### 步骤 3: 部署

```bash
# Build and switch
sudo nixos-rebuild switch --flake .#atlas
sudo darwin-rebuild switch --flake .#charlie

# Check service status
sudo systemctl status cloudflared
journalctl -u cloudflared -f

# Verify tunnel
cloudflared tunnel list
cloudflared tunnel route ip list
```

## 外部设备配置

### WARP 客户端（主要访问方式）

1. 在外部设备上安装 Cloudflare WARP (1.1.1.1)
2. 选择 "使用团队/组织 (Zero Trust)"
3. 输入您的团队名称（来自 Cloudflare Zero Trust）
4. 使用您的账户登录
5. 测试连接性（任一 tunnel 可用即可）：
   ```bash
   ssh c1@192.168.50.227  # Linux 服务器 (atlas)
   ssh c1@192.168.50.143  # Mac (charlie)
   ```

### 浏览器 SSH（紧急访问）

1. **Cloudflare 控制台** → Zero Trust → Access → Applications
2. **添加自托管应用（atlas）**：
   - 名称: SSH Linux (atlas)
   - 域名: `ssh-linux.your-domain.com`
   - 服务: SSH → `192.168.50.227:22`  # atlas (Linux)
   - 浏览器渲染: SSH
3. **添加自托管应用（charlie）**：
   - 名称: SSH Mac (charlie)
   - 域名: `ssh-mac.your-domain.com`
   - 服务: SSH → `192.168.50.143:22`  # charlie (macOS)
   - 浏览器渲染: SSH
4. **访问 URL**：
   - `https://ssh-linux.your-domain.com`
   - `https://ssh-mac.your-domain.com`

**注意**：浏览器 SSH 需要服务器用户与邮箱前缀匹配（例如 `siyuan.arc@gmail.com` → 用户 `siyuan.arc`）。

## 安全注意事项

### SSH 配置
确保 Linux/Mac 上的 SSH 服务器有以下配置：
```bash
# /etc/ssh/sshd_config
PasswordAuthentication no
PermitRootLogin no
PubkeyAuthentication yes
AllowUsers c1 siyuan.arc  # Browser SSH user
```

### Cloudflare 访问策略
- 为所有应用启用 MFA
- 仅限制对您邮箱的访问
- 设置会话持续时间（例如 24 小时）
- 启用审计日志

### 防火墙规则
在 Linux 服务器上：
```bash
sudo ufw allow from 192.168.50.0/24 to any port 22
sudo ufw default deny incoming
```

## 故障排除

### 服务问题
```bash
# Check logs
journalctl -u cloudflared -f

# Verify tunnel connectivity
cloudflared tunnel list
cloudflared tunnel info <tunnel-id>

# Test WARP routing
cloudflared tunnel route ip list
```

### WARP 连接问题
1. 确认设备已注册到 Zero Trust 组织
2. 检查 WARP 客户端连接状态
3. 确保家庭防火墙允许 ICMP/SSH
4. 测试 `ping 192.168.50.227`  # atlas (Linux 服务器)
5. 测试 `ping 192.168.50.143`  # charlie (macOS)

### 浏览器 SSH 问题
1. 确认服务器用户存在（邮箱前缀）
2. 临时启用密码认证进行测试
3. 检查 Cloudflare Access 策略配置
4. 验证 DNS 记录已传播

## 与现有脚本集成

`/Users/c1/Work/edge` 中的 TypeScript 部署脚本可用于初始设置，但 Nix 管理持续服务。使用脚本进行：

1. **初始隧道创建**: `npm run deploy:setup`
2. **WARP 路由**: `npm run deploy:configure`
3. **浏览器 SSH 设置**: `npm run deploy:browser-ssh`

然后切换到 Nix 进行持久管理。

## 维护

### 常规检查
- 监控 cloudflared 服务状态
- 审查 Cloudflare Access 日志
- 定期更新 SSH 密钥
- 保持 NixOS/dotfiles 更新

### 备份
```bash
# Backup important files
tar -czf cloudflare-backup.tar.gz \
  ~/.cloudflared/ \
  /etc/systemd/system/cloudflared.service \
  hosts/<hostname>/secrets/cloudflared-credentials.age
```

## 参考

- [Cloudflare Zero Trust Docs](https://developers.cloudflare.com/cloudflare-one/)
- [Cloudflare Tunnel Local Management](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/tunnel-guide/local/)
- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Age Encryption](https://github.com/FiloSottile/age)

## 支持

对于 Nix 模块问题：
1. 检查服务日志: `journalctl -u cloudflared`
2. 审查主机配置语法
3. 确保 age 秘密已正确加密
4. 验证隧道 ID 和凭证

对于 Cloudflare 问题：
1. 检查 Zero Trust 控制台配置
2. 验证域名 DNS 设置
3. 审查 Access 策略日志