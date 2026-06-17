# Axiom Default Modularization - 任务清单

## 快速恢复
**当前阶段**: Review & Delivery
**当前检查项**: ready for PR lifecycle
**进度**: 11/11 任务完成

---

## 阶段 1: Contract ✅ COMPLETE
- [x] 物化任务契约 | 验收: `plan.md` 覆盖目标、问题、验收、范围、约束、风险、non-goals
- [x] 回读任务文档 | 验收: `plan.md` 与 `tasks.md` 不是占位骨架
- [x] 建立隔离 worktree | 验收: 修改不直接发生在主工作区

## 阶段 2: Design ✅ COMPLETE
- [x] 写入短 RFC | 验收: `docs/rfc.md` 说明模块边界、取舍、验证和回滚
- [x] 审查 RFC | 验收: `docs/review-rfc.md` 明确 PASS 或需返工

## 阶段 3: Implementation ✅ COMPLETE
- [x] 删除明确重复/无效的 Axiom host 配置 | 验收: 删除项有现有模块默认或无消费者依据
- [x] 抽出 reverse SSH / Opencode / healthcheck 边界 | 验收: Axiom 使用模块入口，重复事实减少
- [x] 清理硬编码和小型 shared-module 债务 | 验收: 用户/home、未用 binding、重复 audio constants 等被收束

## 阶段 4: Verification ✅ COMPLETE
- [x] 运行 Nix 配置事实检查 | 验收: 关键 Axiom service/ingress/timer facts 符合预期
- [x] 运行 Nix build | 验收: `nix build .#nixosConfigurations.axiom.config.system.build.toplevel` 成功

## 阶段 5: Review & Delivery ✅ COMPLETE
- [x] 记录 review/walkthrough/wiki | 验收: 验证证据、交付摘要和可复用结论落到 Legion 文档
