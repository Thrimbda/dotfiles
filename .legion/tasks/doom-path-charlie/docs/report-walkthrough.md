# Report Walkthrough

## Profile

implementation

## Reviewer Summary

- 本任务修复 charlie 上 Doom Emacs CLI 不在 `PATH` 的问题。
- Emacs 继续使用直接安装的 `/Applications/Emacs.app`，没有启用 Nix Emacs 模块。
- 验证已覆盖 Nix 语法和 charlie 生成的 `.config/zsh/.zshenv` 内容。
- Review 结论为 PASS，无 blocking findings。
- PR lifecycle 尚未完成。Rendered preview 记录为 artifact-only/blocker，因为仓库没有现成 Pages PR preview workflow。

## Scope

In scope:

- 修改 `hosts/charlie/default.nix` 的 `modules.shell.zsh.envInit`。
- 将 `$XDG_CONFIG_HOME/emacs/bin` 加入 charlie zsh PATH。
- 将 `/Applications/Emacs.app/Contents/MacOS/bin` 加入 charlie zsh PATH。
- 记录 Legion task、验证、review 和 walkthrough 证据。

Out of scope:

- 不启用 `modules.editors.emacs.enable`。
- 不安装或升级 Emacs。
- 不修改其它 host。
- 不修改 Doom repo 或 private Doom 配置。

## Evidence Map

| Claim | Evidence | Status |
|---|---|---|
| 变更只影响 charlie host PATH 初始化 | `hosts/charlie/default.nix`; `docs/review-change.md` | PASS |
| 不启用 Nix Emacs 模块 | `hosts/charlie/default.nix`; `docs/review-change.md` | PASS |
| Nix 语法有效 | `docs/test-report.md` | PASS |
| 生成的 `.zshenv` 包含 Doom bin 和 Emacs.app shim | `docs/test-report.md` | PASS |
| 交付审查无阻塞项 | `docs/review-change.md` | PASS |

## What Changed / What Was Decided

在 charlie 的 `modules.shell.zsh.envInit` 中 prepend 两个目录：

```zsh
$XDG_CONFIG_HOME/emacs/bin
/Applications/Emacs.app/Contents/MacOS/bin
```

这样 `doom` wrapper 和直接安装的 Emacs.app CLI shim 都会被 zsh 找到。该方案保持当前 Emacs 安装方式，不把 Emacs 切到 Nix 管理。

## Verification / Review Status

- `nix-instantiate --parse hosts/charlie/default.nix >/dev/null` 通过。
- `nix eval --raw --no-eval-cache '.#darwinConfigurations.charlie.config.home-manager.users.c1.home.file.".config/zsh/.zshenv".text'` 输出包含新增 PATH 片段。
- `docs/review-change.md` 结论为 PASS。

## Risks and Limits

- 如果未来 Emacs.app 不再位于 `/Applications/Emacs.app`，需要更新 shim 路径。
- 如果 Doom 安装目录不再是 `$XDG_CONFIG_HOME/emacs`，需要更新 Doom bin 路径。
- 本次未执行 `darwin-rebuild switch`，避免在 PR worktree 验证阶段改变用户机器状态。

## Reviewer Checklist

- [ ] 确认 charlie host 使用直接安装的 Emacs.app。
- [ ] 确认没有误启用 Nix Emacs 模块。
- [ ] 确认 PATH prepend 顺序符合预期。
- [ ] 确认验证证据足以覆盖本次配置变更。

## Next Stage

PR-backed lifecycle 仍需继续：`legion-wiki` 写回、commit、rebase、push、PR 创建或更新、checks/review follow-up、auto-merge 尝试、cleanup 和主工作区 refresh。Render handoff 记录为 artifact-only/blocker：仓库没有现成 `.github` Pages PR preview workflow，新增 workflow 会扩大本次 PATH 修复 scope；reviewer 可直接查看 PR 中的 `docs/report-walkthrough.html` artifact，若需要稳定 rendered URL 应另开任务配置 `pr-html-render` workflow。
