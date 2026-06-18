# Test Report

## 验证命令

- `nix eval --raw '.#nixosConfigurations.axiom.config.home-manager.users.c1.home.file.".config/hypr/workspaces.conf".text'`
- `nix eval --raw '.#nixosConfigurations.azar.config.home-manager.users.c1.home.file.".config/hypr/workspaces.conf".text'`
- `nix eval --raw '.#nixosConfigurations.axiom.config.home-manager.users.c1.home.file.".config/hypr/custom/keybinds.conf".text'`
- `nix eval --raw '.#nixosConfigurations.axiom.config.home-manager.users.c1.home.file.".config/hypr/custom/keybinds.conf".text' | rg 'SUPER\+ALT|SUPER\+SHIFT\+ALT|SUPER\+ALT\+SHIFT'`
- `nix eval --raw '.#nixosConfigurations.axiom.config.home-manager.users.c1.home.file.".config/hypr/custom/keybinds.conf".text' | rg 'SUPER\+ALT, [0-9]|SUPER\+ALT\+SHIFT, [0-9]'`
- `nix build --no-link --print-out-paths '.#nixosConfigurations.axiom.config.home-manager.users.c1.home.activationPackage'`
- `git diff --check`

## 结果

- `workspaces.conf` 现在生成：
  - `$PRIMARY_MONITOR = DP-4`
  - `$SECONDARY_MONITOR = DP-5`
  - `workspace=1..10,monitor:$PRIMARY_MONITOR`
  - `workspace=11..20,monitor:$SECONDARY_MONITOR`
- Axiom 显式启用 `modules.desktop.hyprland.workspaces.secondary.enable`，因此二屏 workspace 只对 Axiom 打开。
- `azar` 作为另一个多显示器 host，仍只生成 workspace 1..10，未被本次 Axiom scoped 改动带上 11..20。
- `keybinds.conf` 保留原有：
  - `SUPER+1..9,0 -> workspace 1..10`
  - `SUPER+SHIFT+1..9,0 -> movetoworkspace 1..10`
- `keybinds.conf` 新增：
  - `SUPER+ALT+1..9,0 -> workspace 11..20`
  - `SUPER+ALT+SHIFT+1..9,0 -> movetoworkspace 11..20`
- ALT 组合冲突检查显示既有 `SUPER+ALT` 绑定只在 `R`/`S` 等非数字键上；数字键位没有冲突。
- Home Manager activation package 构建成功，并生成更新后的 `axiom-keybindings.txt`。
- `git diff --check` 通过。

## 跳过项

- 尝试运行 `Hyprland --verify-config`，但当前 Hyprland 0.53.3 命令解析时回到 checked-in source config，并命中既有 `source=` glob 路径限制，未能作为本次改动的有效证明。因此本报告不把它计为通过证据。

## 选择理由

本次改动只影响生成的 workspace、keybind 和帮助文本。直接 evaluate 这些 Home Manager file outputs 比全量系统验证更精确；Home Manager activation build 证明相关 generated files 和帮助脚本可构建；冲突检查聚焦用户要求的 `SUPER+ALT` 数字组合。
