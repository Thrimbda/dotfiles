# Report Walkthrough

## Mode

implementation

## Reviewer Summary

- 移除 Axiom 对 `8.159.128.125` 的 system-wide hardcoded SSH host-key pin。
- 远端重装后，Nix 不再把旧 key 写入 `/etc/ssh/ssh_known_hosts` 阻止登录。
- Reusable reverse-ssh module 的 `remoteHostKey` opt-in 能力保留。

## Evidence

- 验证: `docs/test-report.md`
- 审查: `docs/review-change.md`
- 任务契约: `plan.md`

## Risks

- 这不自动清理用户 known_hosts；如果用户文件里也有旧 key，仍需手动移除。
- 这不关闭 SSH host-key checking；首次连接新装远端仍需要用户确认新 key。
