# Expose cybion on acorn via nginx at cybion.0xc1.wang with nix-ld runtime - 任务清单

## 快速恢复

**当前阶段**: 阶段 3 - deliver
**当前检查项**: git-worktree-pr: open PR, merge, clean worktree, refresh main workspace
**进度**: 5/9 任务完成
---

## 阶段 1: design-gate ✅ COMPLETE

- [x] spec-rfc: short RFC with options, decision, verification for the ingress change | 验收: docs/rfc.md exists with options, decision, and verification sections
- [x] review-rfc: adversarial review of the RFC | 验收: review-rfc records PASS
---

## 阶段 2: implement ✅ COMPLETE

- [x] engineer: nix-ld revert plus cybion nginx module in an isolated worktree | 验收: platform.nix override removed; cybion.nix created; default.nix imports it
- [x] verify-change: evaluate or build the acorn configuration on Axiom and inspect generated nginx config | 验收: acorn toplevel builds on Axiom; nginx config contains the cybion vhost
- [x] review-change: review the diff for blast radius on existing vhosts | 验收: review records ready with no blockers
---

## 阶段 3: deliver ⏳ NOT STARTED

- [ ] git-worktree-pr: open PR, merge, clean worktree, refresh main workspace | 验收: PR merged; worktree removed; main workspace refreshed ← CURRENT
- [ ] rollout: create Cloudflare DNS record, deploy with mandated nixos-rebuild command, swap in pristine binaries, restart controller and worker | 验收: A record exists; acorn switch succeeds; pristine binaries running
- [ ] validate: public https health check, ACME cert state, worker tunnel online | 验收: https://cybion.0xc1.wang/health returns ok; cert issued; worker tunnel connected
- [ ] report-walkthrough and legion-wiki writeback | 验收: walkthrough delivered; wiki updated
---

## 发现的新任务

(暂无)
---

*最后更新: 2026-08-24 10:40*
