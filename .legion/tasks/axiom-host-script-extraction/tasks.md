# Axiom Host Script Extraction - 任务清单

## 快速恢复
**当前阶段**: PR Lifecycle
**当前检查项**: commit / push / PR
**进度**: 10/10 任务完成

---

## 阶段 1: Contract ✅ DONE
- [x] 物化任务契约 | 验收: `plan.md` 明确 aggressive modularization 目标与 non-goals
- [x] 回读任务文档 | 验收: `plan.md` / `tasks.md` 不是占位骨架

## 阶段 2: Implementation ✅ DONE
- [x] 识别剩余 inline script clusters | 验收: 明确 Caelestia/audio/todesk/healthcheck 等迁移点
- [x] 抽出 focused modules/options | 验收: host 只保留 facts，旧 inline shape 不保留
- [x] 删除或压缩 host 内联脚本 | 验收: `hosts/axiom/default.nix` 行数和脚本体显著减少

## 阶段 3: Verification ✅ DONE
- [x] 运行 focused facts eval | 验收: 关键生成事实保持预期
- [x] 运行 Nix build | 验收: `nix build .#nixosConfigurations.axiom.config.system.build.toplevel` 成功

## 阶段 4: Review & Delivery ✅ DONE
- [x] 执行 review-change | 验收: `docs/review-change.md` PASS 或明确返工
- [x] 生成 walkthrough/PR body | 验收: reviewer-facing 证据完整
- [x] wiki writeback | 验收: durable knowledge 完整

## 阶段 5: PR Lifecycle 🟡 IN PROGRESS
- [ ] commit / push / PR | 验收: PR 创建并尝试 auto-merge ← CURRENT
