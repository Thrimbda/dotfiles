# doom-path-charlie Log

## 2026-07-09

- 用户确认当前 Emacs 是直接安装的，不希望通过 Nix Emacs 模块解决。
- 已验证 `/Applications/Emacs.app/Contents/MacOS/bin/emacs` 存在，`$XDG_CONFIG_HOME/emacs/bin/doom` 存在。
- 已验证临时 PATH 包含 `$HOME/.config/emacs/bin` 和 `/Applications/Emacs.app/Contents/MacOS/bin` 后，`doom --version` 返回 `3.0.0-pre`。
- 入口判断：Legion-managed 仓库，修改型低风险任务；无需 RFC，但需要 `git-worktree-pr` envelope。
- Base ref：`origin/master`。
- Branch：`legion/doom-path-charlie-zsh-path`。
- Worktree：`.worktrees/doom-path-charlie`。
- 实现决策：只在 `hosts/charlie/default.nix` 的 `modules.shell.zsh.envInit` 中 prepend Doom bin 和 Emacs.app CLI shim，不启用 `modules.editors.emacs.enable`。
- 验证：`nix-instantiate --parse hosts/charlie/default.nix >/dev/null` 通过。
- 验证：`nix eval --raw --no-eval-cache '.#darwinConfigurations.charlie.config.home-manager.users.c1.home.file.".config/zsh/.zshenv".text'` 的输出包含 `$XDG_CONFIG_HOME/emacs/bin` 与 `/Applications/Emacs.app/Contents/MacOS/bin`。
- Review：PASS。改动在 scope 内，只影响 charlie zsh env 初始化，没有启用 Nix Emacs 模块，没有安全触发项。
- Walkthrough：已生成 `docs/report-walkthrough.html`、`docs/report-walkthrough.md` 与 `docs/pr-body.md`。
- Render handoff：artifact-only/blocker。仓库没有现成 `.github` Pages PR preview workflow，新增 workflow 会扩大本次 PATH 修复 scope；reviewer 可直接查看 PR 中的 HTML artifact。若需要稳定 rendered URL，应另开任务配置 `pr-html-render` workflow 和 Pages settings。
- Wiki writeback：新增 `.legion/wiki/tasks/doom-path-charlie.md`，更新 `.legion/wiki/index.md`、`.legion/wiki/patterns.md` 与 `.legion/wiki/log.md`。
- Git lifecycle：提交 `d8287aa7` 已推送到 `origin/legion/doom-path-charlie-zsh-path`，PR 已创建：`https://github.com/Thrimbda/dotfiles/pull/130`。
