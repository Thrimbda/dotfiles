# Design-lite: Aliyun Acorn Nix Cache Mirror

## 背景

`aliyun-acorn` 位于阿里云 ECS 环境，官方 Nix cache 和海外 Cachix 在国内网络下可能较慢。仓库全局配置已经声明 nix-community 与 Hyprland Cachix；NixOS 会自动补充 `https://cache.nixos.org/` 和官方 trusted public key。本任务需要在不影响其他 hosts 的情况下，让 `aliyun-acorn` 优先尝试国内 mirrors，并允许 TCP 2222 通过 NixOS firewall。

## 方案

在 `hosts/aliyun-acorn/default.nix` 的 host config 中添加 host-scoped Nix settings：

```nix
nix.settings.substituters = lib.mkBefore [
  "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
  "https://mirrors.ustc.edu.cn/nix-channels/store"
  "https://mirror.sjtu.edu.cn/nix-channels/store"
];
```

`lib.mkBefore` 会把 TUNA、USTC、SJTU mirrors 放在已有全局 substituters 前面，同时保留仓库现有 Cachix 和 NixOS 默认官方 cache fallback。最终求值必须继续包含 `https://cache.nixos.org/` 和官方 `cache.nixos.org-1:6NCHdD59X431o0gW...` trusted public key。

同一 host config 中将 `2222` 加入 `networking.firewall.allowedTCPPorts`。本任务不新增该端口背后的服务，也不修改云安全组；这里只处理 NixOS 防火墙。

## 替代方案

- `lib.mkForce` 只使用国内 mirror: 在官方 cache 不可达时有用，但会丢失 Cachix 和官方 fallback，动态 mirror 缺 nar 时更容易失败。本任务不采用。
- 修改全局 `default.nix`: 会影响所有 hosts，不符合只优化阿里云机器的目标。本任务不采用。
- 修改 `flake.nix` input 到国内 nixpkgs git mirror: 能改善 nixpkgs input 拉取，但会影响全仓库 lock/input 策略，也不能解决其他 GitHub inputs。本任务不采用。
- 修改 SSH/OpenSSH 服务端口: 这会改变远程访问语义，超出“打开 firewall TCP 2222”的当前需求。本任务不采用。

## 验证

- `nix eval '.#nixosConfigurations.aliyun-acorn.config.nix.settings.substituters' --json`
- `nix eval '.#nixosConfigurations.aliyun-acorn.config.nix.settings.trusted-public-keys' --json`
- `nix eval '.#nixosConfigurations.aliyun-acorn.config.networking.firewall.allowedTCPPorts' --json`
- `nix eval './hosts/aliyun-acorn/image#aliyun-image.drvPath'`

## 回滚

删除 `hosts/aliyun-acorn/default.nix` 中新增的 domestic mirrors 和 TCP 2222 firewall entry，或 revert 本 PR。回滚不会迁移数据，也不会影响其他 host。

## 临时使用说明

如果某台机器只想单次使用国内 cache，不修改 NixOS 配置，可以在命令上加：

```bash
nixos-rebuild switch --option substituters "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store https://mirrors.ustc.edu.cn/nix-channels/store https://mirror.sjtu.edu.cn/nix-channels/store https://cache.nixos.org/"
```

普通 `nix` 命令同理：

```bash
nix shell nixpkgs#cowsay --option substituters "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store https://mirrors.ustc.edu.cn/nix-channels/store https://mirror.sjtu.edu.cn/nix-channels/store https://cache.nixos.org/"
```
