# Test Report: Aliyun Acorn Nix Cache Mirror

## 摘要

结果: PASS

本次验证聚焦两个验收点：最终 substituter 合并顺序，以及 `aliyun-acorn` NixOS 配置能否继续求值到 system toplevel derivation。

## 命令与结果

### 1. 验证最终 substituter 顺序

命令：

```bash
nix eval '.#nixosConfigurations.aliyun-acorn.config.nix.settings.substituters' --json
```

结果：

```json
[
  "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store",
  "https://nix-community.cachix.org",
  "https://hyprland.cachix.org",
  "https://cache.nixos.org/"
]
```

说明：TUNA mirror 位于第一位，既有 Cachix 与官方 cache 仍作为 fallback。命令输出前出现一次 `SQLite database ... is busy`，Nix 标记为 `error (ignored)` 并继续返回正确结果；不影响本验证结论。

### 2. 验证 `aliyun-acorn` toplevel 求值

命令：

```bash
nix eval '.#nixosConfigurations.aliyun-acorn.config.system.build.toplevel.drvPath'
```

结果：

```text
"/nix/store/n7bzvsgd0nj23ackg7dd70bkblvnqbn5-nixos-system-aliyun-acorn-25.11.20260203.e576e3c.drv"
```

说明：配置求值成功，新增 host-level `nix.settings.substituters` 没有破坏 NixOS 模块合并或 system build graph。

## 为什么选择这些命令

- `substituters` eval 直接证明 `lib.mkBefore` 的最终合并结果，覆盖本任务最关键的行为变化。
- `toplevel.drvPath` eval 证明 host 配置整体仍可被 NixOS 求值，成本低且和本次配置改动直接相关。
- 未运行完整 `nixos-rebuild switch`，因为这会修改当前机器系统状态，而本任务只需要证明目标 host 配置可求值。

## 临时切换 cache 用法

不落盘修改某台机器配置时，可以在单次命令上覆盖 substituters：

```bash
nixos-rebuild switch --option substituters "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store https://cache.nixos.org/"
```

普通 `nix` 命令同理：

```bash
nix shell nixpkgs#cowsay --option substituters "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store https://cache.nixos.org/"
```

如果希望保留当前配置里的 substituters，只是临时追加，可优先使用命令自身支持的 `--substituters`/`--option extra-substituters` 语义；如果要完全替换本次命令的列表，则使用 `--option substituters`。

## 跳过项

- 未对 TUNA/USTC/SJTUG 做速度 benchmark；这不是本任务目标。
- 未修改 flake inputs 或验证 GitHub 下载加速；这属于后续独立问题。
