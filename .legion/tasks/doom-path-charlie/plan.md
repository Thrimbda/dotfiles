# doom-path-charlie

## 目标

让 charlie 上直接安装的 Doom Emacs CLI 可以从 zsh 中直接调用 `doom`，同时继续保持 Emacs 由 `/Applications/Emacs.app` 提供，而不是启用 Nix 管理的 Emacs 模块。

## 问题

当前 `doom` wrapper 位于 `$XDG_CONFIG_HOME/emacs/bin/doom`，直接安装的 Emacs CLI shim 位于 `/Applications/Emacs.app/Contents/MacOS/bin/emacs`，但 charlie 生成的 zsh 环境没有把这两个目录加入 `PATH`。因此 shell 找不到 `doom`，而即使用绝对路径运行 `doom`，也会因为找不到 `emacs` 失败。

## 验收标准

- charlie 的 zsh 初始化会把 `$XDG_CONFIG_HOME/emacs/bin` 加入 `PATH`。
- charlie 的 zsh 初始化会把 `/Applications/Emacs.app/Contents/MacOS/bin` 加入 `PATH`。
- 不启用 `modules.editors.emacs.enable`，避免把 Emacs 切换为 Nix 管理。
- 改动只影响 charlie host 配置。
- Nix 配置语法检查通过。

## 范围

- 修改 `hosts/charlie/default.nix` 中的 `modules.shell.zsh` 配置。
- 新增本任务的 Legion 过程文档与验证记录。

## 非目标

- 不安装、升级或迁移 Emacs。
- 不启用 Nix Emacs 模块。
- 不修改其它 host 的 PATH。
- 不改 Doom Emacs repo 或 private Doom 配置。

## 假设

- charlie 上的 Emacs 继续由 `/Applications/Emacs.app` 提供。
- Doom Emacs 安装目录继续遵循 XDG 路径，即 `$XDG_CONFIG_HOME/emacs`。
- 现有 zsh 模块会把 `modules.shell.zsh.envInit` 写入生成的 `.zshenv`。

## 约束

- 这是低风险 PATH 配置修复，不需要 RFC。
- PATH 追加应使用 zsh 的 `path` 数组和 `typeset -U path PATH`，保持现有 dotfiles 风格并去重。
- 不应覆盖既有 PATH，只能 prepend 所需目录。

## 风险

- 如果未来 Emacs.app 位置变化，`emacs` shim 路径需要同步更新。
- 如果 Doom 安装目录不再是 `$XDG_CONFIG_HOME/emacs`，`doom` 路径也需要调整。

## 推荐方向

在 charlie host 的 `modules.shell.zsh.envInit` 中 prepend Doom bin 和 Emacs.app CLI shim 路径。这比启用通用 Emacs 模块更贴合当前安装方式，也避免让 Nix 接管 Emacs。

## 阶段

1. `brainstorm`: 明确任务契约并落盘。
2. `engineer`: 在 charlie zsh env 初始化中加入 PATH。
3. `verify-change`: 运行 Nix 语法检查并记录结果。
4. `review-change`: 检查 scope、风险和交付质量。
5. `report-walkthrough`: 输出 reviewer-facing 摘要。
6. `legion-wiki`: 写回可复用结论。
