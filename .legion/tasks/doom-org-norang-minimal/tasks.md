# Doom Org/Norang Minimal - 任务清单

## 快速恢复

**当前阶段**: complete
**当前检查项**: 任务已完成
**进度**: 25/25 任务完成

---

## 阶段 1: brainstorm ✅ COMPLETE

- [x] 建立任务目标、范围、验收和非目标 | 验收: `plan.md` 包含稳定 contract
- [x] 回读 `plan.md` 与 `tasks.md` | 验收: 文档不是占位骨架

## 阶段 2: engineer ✅ COMPLETE

- [x] 建立符合 workflow 要求的 Git/worktree 执行环境 | 验收: 修改型工作不直接污染主工作区
- [x] 精简 `init.el` 模块 | 验收: 只保留 Org/Norang 必需模块和基础支撑
- [x] 精简 `packages.el` 包列表 | 验收: 移除非目标包，保留必要包
- [x] 整理 `config.el` 中与被移除模块绑定的配置 | 验收: 不引用已移除模块造成启动错误
- [x] 修复 `bh-org.el` 旧接口兼容问题 | 验收: `org-iswitchb`、`incf`、Babel `sh`/`ammonite` 风险已处理

## 阶段 3: verify-change ✅ COMPLETE

- [x] 运行 Doom 同步或可替代 bootstrap 验证 | 验收: 记录命令和结果
- [x] 运行 Emacs batch 加载验证 | 验收: `bh-org.el` 在当前 Org 环境可加载
- [x] 检查 Doom doctor 残余问题 | 验收: 报告是否仍与 `straight` bootstrap 或外部环境有关
- [x] 写入 `docs/test-report.md` | 验收: 验证证据可审阅

## 阶段 4: review-change ✅ COMPLETE

- [x] 审查 diff 是否越界 | 验收: 未修改 Org 数据或无关 dotfiles
- [x] 审查风险是否记录 | 验收: GPG key、Babel language、Doom bootstrap 风险有说明
- [x] 写入 `docs/review-change.md` | 验收: 交付判断清晰

## 阶段 5: report-walkthrough ✅ COMPLETE

- [x] 写入 `docs/report-walkthrough.md` | 验收: Reviewer 可快速理解变更与验证
- [x] 写入 `docs/pr-body.md` | 验收: 可用于 PR 或手工审阅摘要

## 阶段 6: legion-wiki ✅ COMPLETE

- [x] 写回 `.legion/wiki/tasks/doom-org-norang-minimal.md` | 验收: 当前任务结论可从 wiki 查询
- [x] 如有跨任务规则，写回 wiki decisions/patterns/maintenance | 验收: 只提升可复用结论

## 阶段 7: git-worktree-pr ✅ COMPLETE

- [x] 提交 Doom worktree 变更 | 验收: commit 只包含 `init.el`、`packages.el`、`config.el`、`bh-org.el`
- [x] rebase/refresh 分支到 `origin/master` | 验收: 推送前基线最新
- [x] 推送 `legion/doom-org-norang-minimal-org` | 验收: remote branch 可用于 PR
- [x] 创建 PR 并使用 `docs/pr-body.md` | 验收: PR URL 记录到 raw docs
- [x] 记录 render handoff 终态 | 验收: URL、artifact-only fallback 或阻塞原因明确
- [x] 跟进 checks/review 到终态 | 验收: 合并、关闭或阻塞状态可审阅
- [x] 清理 worktree 并刷新主 Doom 配置 | 验收: active `~/.config/doom` 与终态一致
