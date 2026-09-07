# Doom Org/Norang Minimal - 变更审查

## 结论

PASS。

没有发现 blocking finding。当前实现符合 `plan.md` scope，验证证据足以支持交付；剩余问题均为非阻塞运行环境或后续人工配置项。

## Blocking Findings

无。

## Scope 审查

通过。

实际 Doom worktree diff 只修改：

- `/Users/c1/.config/doom/init.el`
- `/Users/c1/.config/doom/packages.el`
- `/Users/c1/.config/doom/config.el`
- `/Users/c1/.config/doom/bh-org.el`

这与 `plan.md` 的授权范围一致。没有修改 `~/OneDrive/cone` 下的 Org 数据文件，也没有修改 Doom Emacs 本体。

## Correctness / Maintainability 审查

通过。

- `init.el` 从通用 Doom 配置收敛为 Org/Norang 专用模块集合，移除了 LSP、语言 IDE、RSS、terminal、grammar、Treemacs、Magit Forge 等非目标模块。
- `packages.el` 仅保留当前 `config.el` 直接引用的 `mixed-pitch`、`org-appear`、`rime`。
- `config.el` 移除了对未保留模块或未安装包的配置引用，包括 `org-pretty-table`、`org-books`、`projectile` title hook。
- `bh-org.el` 的修补集中在兼容层：`org-switchb`、`cl-incf`、Babel language list、缺失 clock sound 文件保护。未重写 agenda、clock、refile、project skip 等 norang 核心逻辑。

## Security Lens

已应用。触发原因：任务涉及 `org-crypt` / GPG key 配置。

结论：无 blocking security finding。

- 本次变更启用 Doom org `+crypt` 以匹配 `bh-org.el` 中既有 `org-crypt` 使用，但没有新增、导入、暴露或修改任何密钥材料。
- 验证确认 `F0B66B40` 在本机没有 secret key；这会影响实际加密使用，但不是本次 diff 引入的数据暴露风险。
- `org-crypt-key` 的后续修复应由用户提供可用 GPG key；本任务的 non-goal 明确不创建或导入 key。

## 验证证据审查

通过。`docs/test-report.md` 记录了：

- `doom sync` exit 0。
- `doom doctor` exit 0，剩余 warning 为环境类问题。
- `check-parens` 覆盖四个修改文件，exit 0。
- `bh-org.el` batch load exit 0。
- `git diff --check` exit 0。
- Organization default clock task ID 仍存在。

## Non-blocking Notes

- `doom doctor` 的 private config warning 来自隔离 worktree 与实际 `~/.config/doom` 并存；将变更合入实际 config 后应消失。
- `gls` 缺失可能影响 dired 细节体验，但不影响 Org/Norang 核心工作流。
- `~/git/org-mode/lisp` stale load-path 仍是历史兼容逻辑，但当前加载验证已证明它不阻塞。
