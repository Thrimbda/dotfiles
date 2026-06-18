# Axiom Host Policy Extraction - 任务清单

## 快速恢复
**当前阶段**: Review & Delivery
**当前检查项**: PR lifecycle
**进度**: 10/10 任务完成

---

## 阶段 1: Contract ✅ DONE
- [x] 物化任务契约 | 验收: `plan.md` 明确第三轮 host policy extraction 目标与 non-goals
- [x] 回读任务文档 | 验收: `plan.md` / `tasks.md` 不是占位骨架

## 阶段 2: Implementation ✅ DONE
- [x] 识别 PR #94 后剩余 host policy clusters | 验收: 确认可抽取和保留边界
- [x] 抽出 focused modules/options | 验收: host 只保留 facts，不保留旧 inline shape
- [x] 删除或压缩 host policy blocks | 验收: host 行数继续下降且 behavior facts 保留

## 阶段 3: Verification ✅ DONE
- [x] 运行 focused facts eval | 验收: resource policy/status/firewall/network/service facts 符合预期
- [x] 运行 Nix build | 验收: `nix build .#nixosConfigurations.axiom.config.system.build.toplevel` 成功

## 阶段 4: Review & Delivery 🟡 IN PROGRESS
- [x] 执行 review-change | 验收: `docs/review-change.md` PASS 或明确返工
- [x] 生成 walkthrough/PR body | 验收: reviewer-facing 证据完整
- [x] wiki writeback | 验收: durable knowledge 完整
- [ ] PR lifecycle | 验收: PR merged/closed, cleanup attempted, main refresh attempted ← CURRENT
