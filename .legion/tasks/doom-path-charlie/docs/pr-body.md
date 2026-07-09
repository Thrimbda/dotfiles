# Implementation Review

> 本 PR body 只是 PR 创建/更新输入，不代表 checks/review/merge、auto-merge、worktree cleanup 或主工作区 refresh 已完成。

## 交付摘要

- 修复 charlie 上 `doom` 不在 `PATH` 的问题。
- 保持 Emacs 由 `/Applications/Emacs.app` 直接安装提供，不启用 Nix Emacs 模块。
- 通过 Nix parse 与 charlie `.zshenv` 生成内容 eval 验证。

## 范围

**In scope**

- `hosts/charlie/default.nix`
- `.legion/tasks/doom-path-charlie/**`

**Out of scope**

- 不启用 `modules.editors.emacs.enable`
- 不安装或升级 Emacs
- 不修改其它 host
- 不修改 Doom repo 或 private Doom 配置

## 主要改动

- 在 charlie 的 `modules.shell.zsh.envInit` 中 prepend `$XDG_CONFIG_HOME/emacs/bin`。
- 在 charlie 的 `modules.shell.zsh.envInit` 中 prepend `/Applications/Emacs.app/Contents/MacOS/bin`。
- 保留 `typeset -U path PATH` 去重行为。

## 验证与审查

- 验证: `.legion/tasks/doom-path-charlie/docs/test-report.md`
- 变更审查: `.legion/tasks/doom-path-charlie/docs/review-change.md`
- Walkthrough: `.legion/tasks/doom-path-charlie/docs/report-walkthrough.html`
- Render handoff: `.legion/tasks/doom-path-charlie/docs/render-handoff.md`

## 风险与限制

- 如果 Emacs.app 未来移动位置，需要更新 `/Applications/Emacs.app/Contents/MacOS/bin`。
- 如果 Doom 安装目录未来不再是 `$XDG_CONFIG_HOME/emacs`，需要更新 Doom bin 路径。
- 未执行 `darwin-rebuild switch`，因为本次 PR 验证只需要证明配置生成内容正确。

## 评审重点

- [ ] 变更是否只影响 charlie host？
- [ ] 是否避免了 Nix Emacs 模块接管直接安装的 Emacs？
- [ ] 生成的 zsh env 是否包含预期 PATH 片段？
- [ ] 验证证据是否足以支撑本次配置修复？

## 证据链接

- plan: `.legion/tasks/doom-path-charlie/plan.md`
- test-report: `.legion/tasks/doom-path-charlie/docs/test-report.md`
- review-change: `.legion/tasks/doom-path-charlie/docs/review-change.md`
- report-walkthrough: `.legion/tasks/doom-path-charlie/docs/report-walkthrough.html`
- render-handoff: `.legion/tasks/doom-path-charlie/docs/render-handoff.md`
