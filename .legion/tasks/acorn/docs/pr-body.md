# acorn：恢复新配置体系下的构建路径并收敛最小 host 修复

## Summary

- 本次变更聚焦于修复 `acorn` 在当前 flake / nixpkgs 组合下的构建阻塞，并保持修改面收敛在共享 `server` profile、`acorn` host 最小补丁以及 agenix 求值边界。
- 已将失效的 `linux_6_9_hardened` 替换为 `pkgs.linuxPackages_hardened`，避免继续依赖已移除的固定 hardened kernel attr，同时保留 server 默认 hardened kernel 的安全意图。
- `acorn` 上补了最小 host 修复：boot loader、agenix `sshKey`、`theme.active = null`；这些补丁用于恢复主机在新配置体系下的可评估/可构建路径，不扩展为额外重构。
- vaultwarden 功能配置未改；当前仅完成静态边界确认，仍需在目标机补运行时验证，尤其是 secrets、nginx 反代、fail2ban 与 websocket 路径。
- 当前 `nix eval` 已通过；`nix build` 仍未在本 darwin 主机完成，唯一已知阻断是缺少 `x86_64-linux` builder，而不是配置继续失败。

## Validation

- 已通过：`nix eval .#nixosConfigurations.acorn.config.system.build.toplevel.drvPath`
- 已确认：日志中不再出现 `linux_6_9_hardened` 相关错误，说明旧 kernel attr blocker 已移除。
- 当前未完成：`nix build .#nixosConfigurations.acorn.config.system.build.toplevel`
  - 原因：当前环境为 `aarch64-darwin`，缺少 `x86_64-linux` builder
  - 结论：这是平台 builder 阻断，不是本次修复在求值层回归
- 详细结果见：`/Users/c1/dotfiles/.legion/tasks/acorn/docs/test-report.md`

## Risks / Follow-ups

- 运行时主要风险在目标机切换后的 hardened kernel / Azure 兼容性，以及 agenix secrets 链路是否完全正常。
- 合并后建议优先在 `x86_64-linux` builder 或 acorn 目标机执行：
  - `nix build .#nixosConfigurations.acorn.config.system.build.toplevel`
  - `systemctl status vaultwarden nginx fail2ban`
  - `journalctl -u vaultwarden -u nginx -u fail2ban --since "-15m"`
  - `ss -ltnp`
- 部署前请记录当前 generation 并确认 bootloader rollback 可用；若切换异常，使用 bootloader 上一代或 `nixos-rebuild switch --rollback` 回退。
- 相关文档：
  - Plan：`/Users/c1/dotfiles/.legion/tasks/acorn/plan.md`
  - RFC：`/Users/c1/dotfiles/.legion/tasks/acorn/docs/rfc.md`
  - Review RFC：`/Users/c1/dotfiles/.legion/tasks/acorn/docs/review-rfc.md`
  - Code Review：`/Users/c1/dotfiles/.legion/tasks/acorn/docs/review-code.md`
  - Security Review：`/Users/c1/dotfiles/.legion/tasks/acorn/docs/review-security.md`
  - Walkthrough：`/Users/c1/dotfiles/.legion/tasks/acorn/docs/report-walkthrough.md`
