# Undeploy 1Ex Portfolio Adapter - 日志

## 会话进展 (2026-08-24)

### ✅ 已完成

- Stopped `oneex-portfolio-adapter.service`; Acorn remains `inactive/dead`.
- User narrowed the task to service-only undeployment. No browser, 1Exchange, auth-mini, or secret mutation occurred.
- Superseded read-only preflight work made zero external writes; its helper artifacts were removed.
- Removed the exact task-created systemd mask and restored the original unmasked inactive state.
- Removed only the adapter module import from `hosts/acorn/default.nix`.
- Axiom no-cache evaluation reports service `false`, vhost `false`, intentional age secret `true`, and a valid Acorn toplevel derivation.
- Pre-delivery verification and review passed.

### 🟡 进行中

- Rebase onto current `origin/master`, reverify, merge the PR, and deploy from Axiom.

### ⚠️ 阻塞/待定

(暂无)

---

## 关键决策

| 决策 | 原因 | 替代方案 | 日期 |
|------|------|----------|------|
| Remove only the Acorn module import | This is the smallest change that removes the active service and vhost | Delete dormant module/package/secret or mutate external account state | 2026-08-24 |

---

## 快速交接

1. Commit and rebase the one-line production change plus concise task evidence.
2. Reverify, push, merge, and run the mandated Axiom-to-Acorn switch.
3. Verify unit/process/port/vhost absence and unrelated service health.

---

*最后更新: 2026-08-24*
