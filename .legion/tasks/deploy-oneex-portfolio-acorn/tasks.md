# Deploy 1Ex portfolio adapter on Acorn - 任务清单

## 快速恢复

**当前阶段**: 完成
**当前检查项**: 所有阶段已完成；后续仅按 maintenance 项监控上游可用性
**进度**: 4/4 任务完成

---

## 阶段 1: Design and preflight ✅ COMPLETE

- [x] Record the package, secret, nginx, timeout, validation, and rollback design | 验收: RFC identifies the source pin, secret boundary, public hostname, service hardening, and exact remote deployment command.

---

## 阶段 2: Implement Acorn configuration ✅ COMPLETE

- [x] Add the pinned package, systemd/nginx module, ACME certificate, and encrypted environment | 验收: All configuration is scope-limited, secret material is age-encrypted, and the service binds only to loopback.

---

## 阶段 3: Build, deploy, and verify ✅ COMPLETE

- [x] Build locally, switch Acorn remotely, and validate the HTTPS API | 验收: The required remote command succeeds without an Acorn build and authenticated API checks pass.

---

## 阶段 4: Review and delivery ✅ COMPLETE

- [x] Capture verification, review, walkthrough, wiki, and PR lifecycle evidence | 验收: The change is reviewed, merged or explicitly blocked, and its rollout/rollback state is recorded. PR #161 merged; no required checks or review gate were configured.


---

## 发现的新任务

(暂无)


---

*最后更新: 2026-08-18*
