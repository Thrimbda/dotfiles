# RustDesk same-intranet 强制中继交付摘要

> **Mode:** implementation
> **Verdict:** static/build、runtime 与 change review 均 **PASS**，无 blocking finding
> **Production:** 已从当前 dirty candidate 激活；本 PR 只关闭 Git source-of-truth gap，**无需再次 deploy**

## 根因与修复

官方 RustDesk Server 1.1.14 在 `ALWAYS_USE_RELAY=true` 时会设置 `SYMMETRIC`，但 same-intranet 命中后仍进入 `FetchLocalAddr` 分支，导致同出口连接尝试直连而没有到达 hbbr。

- Acorn package override 追加最小 source patch：`true` 时令 `same_intranet=false`，跳过 `FetchLocalAddr` 并进入既有 `PunchHole + SYMMETRIC` relay 链；稳定 `false` 时，原有 WebSocket、LAN 与 same-IP 判断逐项不变。
- Charlie fresh-provision marker 推进到 v10；root provision 通过 `launchctl asuser "$uid"` 在正确的 GUI launchd domain 轮换 `com.carriez.RustDesk_server`。v10 实际运行成功。

## PR scope

1. Acorn package override 与 source patch：`hosts/acorn/default.nix`、`hosts/acorn/patches/rustdesk-server-force-relay-intranet.patch`。
2. Charlie v10 marker 与 GUI-domain restart：`hosts/charlie/default.nix`。
3. Authoritative static/build/runtime evidence：`docs/test-report.md`。
4. Authoritative independent review：`docs/review-change.md`。

不包含 RFC 变更。

## 验证证据

### Static / build — PASS

- Exact source differential、zero-fuzz apply、8-case true/false truth table、fresh package tests、generated units 与完整 Acorn toplevel 均通过。
- Acorn closure 只在 Axiom 使用以下指定命令构建并复制；**Acorn 从未本地 build**：

```bash
nixos-rebuild switch --flake .#acorn --target-host c1@8.159.128.125 --build-host localhost --sudo --ask-sudo-password --use-substitutes -L
```

### Runtime — PASS

- Same-public-IP 会话在 Acorn hbbr 出现 fresh request 并 paired，不再由 `FetchLocalAddr` direct path 获胜。
- 正确密码、远程画面、鼠标点击与键盘输入均通过；错误密码被拒绝。
- Manual finalizer 写入 current stamp，`ready-to-finalize` 已移除；随后 provision fast-skip 以 exit `0` 返回且 process identity 保持。
- 诊断用临时 hosts/route 已清理；恢复正常网络路径后的 final connection smoke 仍通过。

## Reviewer residuals

- 未做长期 relay 带宽、容量、云费用或 failover 验证；Acorn/hbbr 仍是数据面单点。
- Private source patch 需要在每次 RustDesk Server 升级时重新证明必要性、精确应用、`false` 路径不变及 same-intranet runtime。
- 本轮明确覆盖 correct-password 与 wrong-password；old-password / cross-host 未分别执行 fresh negative，不应声明其已通过。

证据：[`test-report.md`](./test-report.md)、[`review-change.md`](./review-change.md)。
