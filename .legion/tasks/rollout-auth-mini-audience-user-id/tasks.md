# Rollout Audience-Bound Gateway User IDs - 任务清单

## 快速恢复

**当前阶段**: (none)
**当前检查项**: (none)
**进度**: 5/5 任务完成

---

## 阶段 1: Configuration and review ✅ COMPLETE

- [x] Create a clean worktree, update the gateway pin and both encrypted environments, build/evaluate, review, merge, and refresh main. | 验收: Merged dotfiles commit contains the correct pin and encrypted env migration with no plaintext secret or user-ID exposure.
- [x] Add explicit cleartext proxy protocol selection required by the new gateway. | 验收: Axiom units evaluate with `UPSTREAM_PROTOCOL=http1` and no `upstream_protocol_cleartext_auto` startup failure.

---

## 阶段 2: Axiom deployment ✅ COMPLETE

- [x] Switch Axiom from refreshed origin/master and verify both gateway services and login redirects. | 验收: Axiom status/opencode gateways run the new binary, read the migrated env, and return correct auth-mini redirects.

---

## 阶段 3: Acorn deployment ✅ COMPLETE

- [x] Switch Acorn using the mandated Axiom build-host command and verify both retained gateway services and login redirects. | 验收: Acorn auth-gateway/frps gateways run the new binary, read the migrated env, and return correct auth-mini redirects without any Acorn-local build.

---

## 阶段 4: Closeout ✅ COMPLETE

- [x] Record verification, review, walkthrough, wiki writeback, PR/deploy evidence, and remaining user browser smoke. | 验收: Task and wiki evidence distinguish completed rollout from credential-bearing browser login smoke.

---

## 发现的新任务

(暂无)

---

*最后更新: 2026-07-31 14:55*
