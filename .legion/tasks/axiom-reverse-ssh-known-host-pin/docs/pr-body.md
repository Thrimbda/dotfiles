## 交付摘要

- 移除 Axiom 对远端 `8.159.128.125` 的 hardcoded SSH host-key pin。
- NixOS 不再通过 `programs.ssh.knownHosts` 把旧 key 写进 `/etc/ssh/ssh_known_hosts`。
- 保留 reusable `modules.services.reverse-ssh.remoteHostKey` 能力，其他 host 仍可显式 opt in。

## 范围

**In scope**

- `hosts/axiom/default.nix` host-local reverse-ssh key pin。
- 轻量 Legion docs 和验证记录。

**Out of scope**

- 不修改 reusable reverse-ssh module。
- 不关闭 SSH host key checking。
- 不自动改写用户 known_hosts。
- 不改变 autossh tunnel topology。

## 验证

- Focused eval: `hasAutosshPin=false`, `programs.ssh.knownHosts={}`。
- `git diff --check` pass。
- `nix build --impure --no-link '.#nixosConfigurations.axiom.config.system.build.toplevel'` pass。

## 风险与限制

- 如果用户 `~/.config/ssh/known_hosts` 或 `~/.ssh/known_hosts` 中仍有旧 key，仍需手动清理。
- 首次连接重装后的远端仍需要按正常 SSH 流程确认新 host key。
