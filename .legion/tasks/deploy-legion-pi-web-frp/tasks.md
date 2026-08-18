# 部署 Legion Pi Web 并通过 Acorn FRP 安全暴露 - 任务清单

## 快速恢复

**当前阶段**: 阶段 6 - Delivery closeout
**当前检查项**: Complete PR lifecycle
**进度**: 5/6 任务完成
---

## 阶段 1: Contract and upstream review ✅ COMPLETE

- [x] Materialize the confirmed contract and recheck PI WEB, FRP, Axiom, and Acorn constraints | 验收: Task contract records exact versions, public hostname, authentication boundary, Acorn safety rule, scope, and non-goals
---

## 阶段 2: Design gate ✅ COMPLETE

- [x] Write and independently review the deployment RFC | 验收: RFC locks topology, service ownership, ports, environment, rollout, verification, and rollback; independent review returns PASS
---

## 阶段 3: Declarative configuration ✅ COMPLETE

- [x] Implement isolated Axiom and Acorn Nix changes | 验收: Only intended dotfiles paths change; evaluation and targeted checks prove no firewall or existing-service regression
---

## 阶段 4: Local and remote deployment ✅ COMPLETE

- [x] Install Legion Pi and PI WEB on Axiom, activate Axiom, then deploy Acorn from Axiom | 验收: Local services are persistent and both host activations succeed without building on Acorn
---

## 阶段 5: Verification and review ✅ COMPLETE

- [x] Verify loopback, auth gateway, FRP, HTTPS, WebSocket, persistence, and rollback evidence | 验收: Independent verification and change review return PASS with no unresolved security blocker
---

## 阶段 6: Delivery closeout ⏳ IN PROGRESS

- [ ] Generate walkthrough, write Wiki disposition, and complete PR lifecycle | 验收: PR reaches terminal state, worktree is cleaned, and dotfiles main workspace is safely refreshed ← CURRENT
---

## 发现的新任务

(暂无)
---

*最后更新: 2026-08-19*
