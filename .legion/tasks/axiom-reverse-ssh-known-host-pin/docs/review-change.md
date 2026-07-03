# Review Change

## 结论

PASS。

## Blocking Findings

无。

## Scope Check

- 只改 Axiom host-local reverse-ssh key pin。
- 未改 reusable `modules/services/reverse-ssh.nix`。
- 未关闭 SSH host key checking。
- 未改 tunnel host、remote port、frp 或 healthcheck拓扑。

## Security Lens

触发点：SSH host-key trust 行为变化。

判断：非阻塞。变更移除的是 stale-prone system-wide hardcoded host-key pin，不是禁用 host-key checking。后续交互式 SSH 或 autossh 会使用正常 SSH known-host 机制；远端重装后的新 key 需要用户显式确认或清理用户 known_hosts。

## Notes

- 如果未来某个稳定远端需要 declarative pin，`modules.services.reverse-ssh.remoteHostKey` 能力仍保留，可按 host opt in。
