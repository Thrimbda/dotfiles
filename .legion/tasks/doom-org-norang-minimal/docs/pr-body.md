# Implementation Review

> 本 PR body 只是 PR 创建/更新输入，不代表 checks/review/merge、auto-merge、worktree cleanup 或主工作区 refresh 已完成。

## 交付摘要

- 精简 Doom private config，使其只服务 Org mode 与 `bh-org.el` / norang 工作流。
- 修复 `bh-org.el` 在 Emacs 30 / Org 9.8 下的旧接口兼容问题。
- 验证与只读审查均通过，剩余风险为非阻塞环境项和 GPG key 后续配置。

## 范围

**In scope**

- `/Users/c1/.config/doom/init.el`
- `/Users/c1/.config/doom/packages.el`
- `/Users/c1/.config/doom/config.el`
- `/Users/c1/.config/doom/bh-org.el`
- `.legion/tasks/doom-org-norang-minimal/**`

**Out of scope**

- `~/OneDrive/cone` Org 数据。
- Doom Emacs 本体升级或降级。
- 新增其它 Org 工作流。
- GPG key 创建、导入或信任配置。

## 主要改动

- `init.el`: 删除 LSP、通用语言模块、Treemacs、RSS、vterm、Magit Forge、grammar 等非目标模块，保留 Org/Norang 与基础支撑。
- `packages.el`: 仅保留 `mixed-pitch`、`org-appear`、`rime`。
- `config.el`: 移除 `org-pretty-table`、`org-books`、`projectile` title hook 等已不适配精简模块集的配置。
- `bh-org.el`: 使用 `org-switchb`、`cl-incf`，删除 Babel `sh`/`ammonite` 加载项，并保护缺失 clock sound 文件。

## 验证与审查

- 验证: `.legion/tasks/doom-org-norang-minimal/docs/test-report.md`
- 变更审查: `.legion/tasks/doom-org-norang-minimal/docs/review-change.md`
- 设计一致性: `.legion/tasks/doom-org-norang-minimal/docs/rfc.md`

## 风险与限制

- `org-crypt-key` 的 `F0B66B40` 在本机没有 secret key，实际加密使用前需用户配置可用 key。
- `doom doctor` 剩余 fontconfig 和 `gls` 环境 warning。
- 当前没有 GUI Emacs 人工烟测。

## 评审重点

- [ ] 变更是否符合只保留 Org/Norang 的任务目标？
- [ ] `bh-org.el` 的 norang 核心逻辑是否保持稳定？
- [ ] 验证证据是否足以支持合入？
- [ ] GPG key 与 GUI smoke test 限制是否已被清楚暴露？

## 证据链接

- plan: `.legion/tasks/doom-org-norang-minimal/plan.md`
- design-lite: `.legion/tasks/doom-org-norang-minimal/docs/rfc.md`
- test-report: `.legion/tasks/doom-org-norang-minimal/docs/test-report.md`
- review-change: `.legion/tasks/doom-org-norang-minimal/docs/review-change.md`
- report-walkthrough: `.legion/tasks/doom-org-norang-minimal/docs/report-walkthrough.md`
- report-walkthrough-html: `.legion/tasks/doom-org-norang-minimal/docs/report-walkthrough.html`
