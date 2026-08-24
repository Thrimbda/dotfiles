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
- PR #203 merged as df26dce7f6b0652172cf5d604527f18d73cd76a5
- Axiom built and activated Acorn generation /nix/store/aasj72hy0vdl7sbgdgfib54x4bnhgggc-nixos-system-acorn-26.05.7813.0dd31db7e6db
- Final verification passed: adapter/ACME units not-found, process absent, port 8090 closed, vhost absent, endpoint 404, critical services active, failed units empty
- Final review, walkthrough, and wiki writeback completed
### 🟡 进行中

- Rebase onto current `origin/master`, reverify, merge the PR, and deploy from Axiom.
### ⚠️ 阻塞/待定

(暂无)

(暂无)
---

## 关键决策

| 决策 | 原因 | 替代方案 | 日期 |
|------|------|----------|------|
| Close service-only undeployment with dormant adapter artifacts and runtime age secret retained | The user requested only the active Acorn deployment be removed; final runtime evidence proves that boundary is gone | Delete dormant artifacts or external account state | 2026-08-24 |
---

## 快速交接

**下次继续从这里开始：**

1. (none)

**注意事项：**

- No browser, 1Exchange, auth-mini, credential, or secret mutation occurred
- Future restoration requires re-importing the module and a reviewed Axiom deployment
---

*最后更新: 2026-08-24 13:46 by Legion CLI*
