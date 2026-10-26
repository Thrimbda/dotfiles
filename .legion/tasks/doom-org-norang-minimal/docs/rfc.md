# Design-lite: Doom Org/Norang Minimal

## 背景

用户明确只使用 Doom Emacs 的 Org mode，并需要 `bh-org.el` / norang 工作流能力。当前配置仍保留多种通用编辑器模块和语言模块，且 `bh-org.el` 存在少数旧接口会影响 Emacs 30 / Org 9.8 加载。

## 决策

采用低风险 design-lite 路径，不写完整 RFC。实现策略如下：

1. `init.el` 只保留基础 completion/UI/file-management、macOS/tty、Org、shell/emacs-lisp 基础支持，以及 Doom 默认绑定。
2. `packages.el` 移除与目标无关的包，保留 `mixed-pitch`、`org-appear`、`rime` 这类当前配置直接引用的包。
3. `config.el` 移除或保护对已删除模块的配置引用，例如 `projectile` frame title hook、`org-pretty-table` 等。
4. `bh-org.el` 只做兼容修补：
   - `org-iswitchb` -> `org-switchb`
   - `incf` -> `cl-incf`，并加载 `cl-lib`
   - Babel load languages 删除 `(sh . t)` 和 `(ammonite . t)`，保留 `(shell . t)`
   - 对不存在的 clock sound 使用条件设置
   - 保留 `org-crypt`，但记录当前 GPG key 风险，不在本任务创建或导入 key

## 取舍

- 不启用 `org +pretty`：当前配置已经显式使用 `org-appear` 与 Doom 的 `+org-pretty-mode` hook；先保持可控，不额外引入 `org-modern` 行为变化。
- 不保留全部历史 source block 语言模块：norang 工作流核心不依赖 Go/Scala/JS/Nix IDE 支持；必要时用户可后续按需加回。
- 不重写 `bh-org.el`：风险集中在兼容修补，避免改动 agenda/clock/refile 判定逻辑。

## 验证

- `doom sync`：验证包集和 autoload 是否能重建。
- `doom doctor`：验证 Doom 环境是否仍有外部阻塞。
- Emacs batch load：直接加载当前 `bh-org.el`，证明修补后的 norang 配置能在当前 Org 环境中加载。

## 回滚

本任务只改配置文件。回滚路径为 `git revert` 或恢复 `/Users/c1/.config/doom` 对应提交；不会触碰用户 Org 数据。
