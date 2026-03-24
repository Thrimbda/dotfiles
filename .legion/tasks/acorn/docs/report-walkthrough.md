# acorn 交付 walkthrough

## 问题背景

- 任务目标：让 `acorn` 适配当前仓库升级后的 flake / nixpkgs 组合，恢复可评估、可构建的 NixOS 配置交付链路。
- 直接根因：共享 `server` profile 仍引用已在当前 nixpkgs 中移除的固定内核 attr：`linux_6_9_hardened`，导致 `acorn` 命中 `role = "server"` 后在构建入口失败。
- 设计依据：本次实现按 RFC 收敛为“最小修复共享 blocker + 最小 host 补丁 + 不扩散修改 vaultwarden 功能配置”。详见：
  - Plan：`/Users/c1/dotfiles/.legion/tasks/acorn/plan.md`
  - RFC：`/Users/c1/dotfiles/.legion/tasks/acorn/docs/rfc.md`
  - RFC Review：`/Users/c1/dotfiles/.legion/tasks/acorn/docs/review-rfc.md`

## 目标与范围

- 绑定 scope：
  - `hosts/acorn/**`
  - `modules/profiles/role/server.nix`
  - `modules/agenix.nix`
- 本次明确不做：
  - 不修改 vaultwarden 功能配置语义
  - 不扩展到 scope 外主机、部署流水线或额外重构
  - 不修改 `.legion` 三文件

## 改动摘要

### 1. 共享 server profile 修复

- 已将失效的 `linux_6_9_hardened` 替换为受支持入口 `pkgs.linuxPackages_hardened`。
- 这次替换保留了“server 默认使用 hardened kernel”的安全意图，同时避免继续绑定会过期的固定版本 attr。

### 2. acorn 最小 host 修复

- 在 `acorn` 上补齐了最小 host 级修复，使其能在当前配置体系下继续完成求值与后续构建路径准备。
- 需在 PR 中明确披露的 host 级补丁包括：
  - boot loader 相关补齐
  - agenix `sshKey` 相关补齐/收敛
  - `theme.active = null`，避免失效主题配置继续阻断主机求值

### 3. agenix 求值边界收敛

- 当前放宽逻辑仅针对无法获得 `currentSystem` 的纯求值场景。
- 真实目标平台/可判定本机构建路径仍保留 `sshKey` 存在性校验，不再通过 host 侧 `checkSshKey = false` 关闭保护。

### 4. vaultwarden 边界保持不变

- vaultwarden 功能配置未改。
- 本次只确认其静态配置边界未被扩散修改；运行时正确性仍需在目标机补验证，不能把“代码未改”表述成“运行时已验证完成”。

## 按模块 / 文件的改动清单

- `modules/profiles/role/server.nix`
  - 将 `linux_6_9_hardened` 替换为 `pkgs.linuxPackages_hardened`
  - 修复共享 server profile 对新 nixpkgs 的不兼容
- `hosts/acorn/**`
  - 补齐最小 host 级配置，使 `acorn` 能适配当前仓库的新配置方式
  - 重点包括 boot loader、agenix `sshKey`、`theme.active = null`
- `modules/agenix.nix`
  - 将断言语义收敛为“纯求值放宽、真实目标构建严格”
  - 保持 secrets/host key 校验默认边界不被永久弱化
- 文档产物
  - `test-report.md`
  - `review-code.md`
  - `review-security.md`
  - 本 walkthrough 与 PR body

## 验证结果

参考：`/Users/c1/dotfiles/.legion/tasks/acorn/docs/test-report.md`

### 已完成验证

- `nix eval .#nixosConfigurations.acorn.config.system.build.toplevel.drvPath`
  - 结果：通过
  - 说明：`acorn` 的 toplevel drvPath 已可成功求出，说明当前配置至少已通过求值层验证。
- 旧 blocker 复核
  - 结果：通过
  - 说明：日志中未再出现 `linux_6_9_hardened` 相关报错，可认为该失效 attr 问题已消失。

### 当前未完成项

- `nix build .#nixosConfigurations.acorn.config.system.build.toplevel`
  - 当前结论：未在本机完成，但原因不是配置继续失败。
  - 已知阻断：当前开发机为 `aarch64-darwin`，缺少 `x86_64-linux` builder。
  - 因此当前状态应表述为：`nix eval` 已通过；`nix build` 目前只受 darwin 缺少 `x86_64-linux` builder 阻断。

### 推荐的后续验证命令 / 步骤

1. 在具备 `x86_64-linux` builder 的环境或目标机执行：
   - `nix build .#nixosConfigurations.acorn.config.system.build.toplevel`
2. 若准备部署，先记录当前 generation，并确认 bootloader 可回退。
3. 在目标机切换后执行：
   - `systemctl status vaultwarden nginx fail2ban`
   - `journalctl -u vaultwarden -u nginx -u fail2ban --since "-15m"`
   - `ss -ltnp`
4. 验证 `vault.0xc1.space`：
   - HTTPS / `forceSSL` 正常
   - websocket 路径 `/notifications/hub` 与 `/notifications/hub/negotiate` 正常
   - 8000 / 3012 后端转发正常
5. 验证 agenix / secrets：
   - `/etc/ssh/ssh_host_ed25519_key` 存在且权限正确
   - `age.secrets.vaultwarden-env` 可解密并被 vaultwarden 正常读取
6. 若切换异常：
   - 从 bootloader 回退上一代，或执行 `nixos-rebuild switch --rollback`

## 风险 / 假设

### 主要风险

- `pkgs.linuxPackages_hardened` 的静态求值已成立，但 Azure/驱动/运行时兼容性仍需目标机验证。
- agenix 当前对“同平台但非目标机”的 Linux builder 语义仍可能偏严格，若后续使用独立 Linux builder，需再次确认 `sshKey` 可用性。
- vaultwarden 功能配置虽未改，但仍需运行时补证据，尤其是 secrets、nginx 反代、fail2ban 与 websocket 路径。

### 当前假设

- 当前已修复求值层 blocker，剩余唯一已知构建阻断来自 builder 平台不匹配。
- 目标机具备有效的 host SSH key 与 age secrets 链路。
- 本次 host 级补丁属于最小修复，不引入额外行为漂移。

## 回滚

- 仓库回滚：回退本次关于 `server.nix` / `acorn` / `agenix` 的 patch。
- 主机回滚：切换前记录当前 generation；若新 generation 异常，优先从 bootloader 选择上一代。
- 在线回滚：若系统仍可登录，可执行 `nixos-rebuild switch --rollback`。

## 后续动作

- 在 `x86_64-linux` builder 或 acorn 目标机上补做真实 `nix build`。
- 完成目标机运行时验证，特别是：
  - Azure 启动正常
  - `vaultwarden` / `nginx` / `fail2ban` 服务与日志正常
  - `vaultwarden-env` secrets 解密链路正常
- 在 PR 中明确说明：vaultwarden 功能配置未改，但仍需在目标机补运行时验证。
- 若后续继续维护，可补文档性注释，说明为何使用 `pkgs.linuxPackages_hardened` 而非固定版本 attr，以及 agenix 断言的边界设计。
