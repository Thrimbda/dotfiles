## Summary

- RustDesk Server 1.1.14 的官方 `ALWAYS_USE_RELAY` 路径在 same-intranet 命中后仍会发送 `FetchLocalAddr`。Acorn 的最小 source patch 使 `true` 跳过该分支并进入既有 relay 链；稳定 `false` 保持原行为。
- Charlie marker 推进到 v10，并用 `launchctl asuser` 在正确的 GUI launchd domain 轮换 user server。

Production 已从当前 dirty candidate 激活。本 PR 用 exact production/evidence diff 关闭 Git source-of-truth gap；**无需再次 deploy**。

## Scope

1. Acorn package override + source patch：`hosts/acorn/default.nix`、`hosts/acorn/patches/rustdesk-server-force-relay-intranet.patch`。
2. Charlie v10 marker + GUI-domain restart：`hosts/charlie/default.nix`。
3. Authoritative verification：`.legion/tasks/rustdesk-self-hosted-remote-access/docs/test-report.md`。
4. Authoritative review：`.legion/tasks/rustdesk-self-hosted-remote-access/docs/review-change.md`。

No RFC change.

## Validation

- **Static/build PASS:** exact patch application、true/false truth table、fresh Rust tests/package checks、generated units 与完整 Acorn toplevel 均通过。
- **Build safety PASS:** Acorn closure 只从 Axiom 使用指定 `nixos-rebuild ... --build-host localhost` 命令构建并复制；Acorn 未执行本地 Nix build。
- **Runtime relay PASS:** same-IP fresh sessions 在 Acorn hbbr paired；correct password、画面、鼠标与键盘通过，wrong password 被拒绝。
- **State/cleanup PASS:** finalizer stamp 存在，ready 已移除，后续 fast-skip exit `0`；临时 route/hosts 清理后 final smoke 仍通过。
- **Change review PASS:** 无 blocking correctness、security、scope 或 evidence finding。

## Residuals

- 长期 relay 带宽、费用、容量与 Acorn/hbbr 单点风险未关闭。
- Private source patch 需随 RustDesk Server 升级重新验证和维护。
- Old-password / cross-host 未分别执行 fresh negative；本 PR 不声明这些 case 已通过。

Walkthrough: [`.legion/tasks/rustdesk-self-hosted-remote-access/docs/report-walkthrough.md`](.legion/tasks/rustdesk-self-hosted-remote-access/docs/report-walkthrough.md)
