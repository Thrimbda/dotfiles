# Aliyun Acorn Nix Cache Mirror - 任务清单

## 快速恢复

**当前阶段**: Delivery
**当前检查项**: 完成 Git lifecycle 或记录 blocker
**进度**: 10/11 任务完成

---

## 阶段 1: Contract ✅ COMPLETE

- [x] 刷新稳定 Legion task contract | 验收: `plan.md` 覆盖三组国内 mirrors、官方 fallback/key、TCP 2222、scope、风险和 image 验证目标。

---

## 阶段 2: Implementation ✅ COMPLETE

- [x] 打开或恢复 `git-worktree-pr` worktree | 验收: implementation 在隔离 worktree/branch 中完成，主工作区不混入无关改动。
- [x] 检查 `hosts/aliyun-acorn` host/image 配置 conventions | 验收: 选择最小 host-scoped 落点，不全局改其他 hosts。
- [x] 配置 domestic substituters 和官方 fallback/key | 验收: 最终列表优先 TUNA、USTC、SJTU，并保留 `cache.nixos.org` fallback/trusted key。
- [x] 放行 firewall TCP 2222 | 验收: `networking.firewall.allowedTCPPorts` 最终包含 `2222`。

---

## 阶段 3: Verification ✅ COMPLETE

- [x] 验证最终 Nix settings 和 firewall 配置 | 验收: `nix eval` 输出 substituters、trusted keys 和 allowed TCP ports 符合 acceptance。
- [x] 验证 image target | 验收: `nix eval` 或 `nix build --dry-run` 覆盖 `./hosts/aliyun-acorn/image#aliyun-image`。

---

## 阶段 4: Review ✅ COMPLETE

- [x] 执行 change review | 验收: `docs/review-change.md` 记录 PASS/FAIL、范围和残余风险。

---

## 阶段 5: Delivery ⏳ PENDING

- [x] 更新 walkthrough 和 PR body | 验收: `docs/report-walkthrough.md` 与 `docs/pr-body.md` 可供 reviewer 使用。
- [x] 执行 wiki writeback | 验收: `.legion/wiki/**` 记录当前可复用知识或明确无需新增。
- [ ] 完成 Git lifecycle 或记录 blocker | 验收: commit/PR/checks/cleanup 状态记录在 `log.md`。 ← CURRENT

---

## 发现的新任务

(暂无)

---

*最后更新: 2026-06-29*
