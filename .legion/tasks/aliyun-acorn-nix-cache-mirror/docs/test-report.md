# Test Report: Aliyun Acorn Nix Cache Mirror

## 摘要

结果: PASS

本次验证聚焦当前验收点：最终 substituter 合并顺序、官方 cache trusted public key、NixOS firewall TCP 端口，以及用户指定的 image flake target 是否可求值。

## 命令与结果

### 1. 验证最终 substituter 顺序

命令：

```bash
nix eval --option eval-cache false '.#nixosConfigurations.aliyun-acorn.config.nix.settings.substituters' --json
```

结果：

```json
[
  "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store",
  "https://mirrors.ustc.edu.cn/nix-channels/store",
  "https://mirror.sjtu.edu.cn/nix-channels/store",
  "https://nix-community.cachix.org",
  "https://hyprland.cachix.org",
  "https://cache.nixos.org/"
]
```

说明：TUNA、USTC、SJTU 位于最前，既有 Cachix 与官方 cache 仍作为 fallback。

### 2. 验证官方 trusted public key

命令：

```bash
nix eval --option eval-cache false '.#nixosConfigurations.aliyun-acorn.config.nix.settings.trusted-public-keys' --json
```

结果：

```json
[
  "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=",
  "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=",
  "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
]
```

说明：官方 `cache.nixos.org` trusted public key 保留，未新增不必要的第三方 signing key。

### 3. 验证 firewall TCP 端口

命令：

```bash
nix eval --option eval-cache false '.#nixosConfigurations.aliyun-acorn.config.networking.firewall.allowedTCPPorts' --json
```

结果：

```json
[22, 80, 443, 2222, 2225, 7000, 34197]
```

说明：最终 NixOS firewall 配置包含 TCP 2222。

### 4. 验证 image flake target

命令：

```bash
nix eval --option eval-cache false './hosts/aliyun-acorn/image#aliyun-image.drvPath'
```

结果：

```text
"/nix/store/93rh6l52186jsb8rg8vlmpxc2dra4jis-nixos-disk-image.drv"
```

说明：用户指定的 `./hosts/aliyun-acorn/image#aliyun-image` target 能求值到 image derivation。

## 为什么选择这些命令

- `substituters` eval 直接证明 `lib.mkBefore` 的最终合并结果，覆盖国内 mirror 优先级与 fallback 保留。
- `trusted-public-keys` eval 直接证明官方 cache key 仍在最终配置中。
- `allowedTCPPorts` eval 直接证明 TCP 2222 已由 `aliyun-acorn` NixOS firewall 放行。
- `aliyun-image.drvPath` eval 覆盖用户指定 image flake target，成本低于完整 image build，并足以证明该 target 可求值。

## 跳过项

- 未运行完整 `nix build ./hosts/aliyun-acorn/image#aliyun-image`，因为会构建 QCOW2 image，成本明显高于本次配置验证需求。
- 未对 TUNA/USTC/SJTU 做速度 benchmark；这不是本任务目标。
- 未修改 Aliyun 安全组或 TCP 2222 背后的服务；本任务只处理 NixOS firewall 配置。
