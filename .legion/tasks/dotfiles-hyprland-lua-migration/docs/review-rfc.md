# Review RFC: Hyprland Config Format Migration

- Task: `dotfiles-hyprland-lua-migration`
- Reviewed artifact: `docs/rfc.md`
- Date: 2026-08-19

## Verdict

**PASS**（含 2 项已在 rfc.md / plan.md 中折回的修正）

## Lenses

### unnecessary complexity

- 无。Option A（require 分层模块）保持现有文件分层，是三个选项中结构变化最小的；Option B（单体）被正确拒绝，Option C（pin 版本）被正确列为延期选项并拒绝。

### weak assumptions

- `hl.on("hyprland.start")` 注册顺序假设存在，但已列入 Verification（部署时确认 `hey hook startup` 先于 xrandr 执行）。即使顺序不成立，两个 handler 互不依赖（env 导入 vs XWayland primary），影响面小，不阻塞。
- `require` 文件必然存在：模块内 7 个生成文件均为无条件下发（monitors 默认 `[{}]` 也生成），成立。
- 其余 API 形状假设均有 2026-08-19 抓取的官方 wiki 证据支撑（hl.monitor/hl.bind flags/hl.window_rule effects/hl.workspace_rule/css_gaps/`on_created_empty`/render.cm_enabled/misc.allow_session_lock_restore/cursor.no_hardware_cursors 均已在 Variables/Monitors/Binds/Window-Rules/Workspace-Rules 页确认存在）。

### missing rollback

- 无。按文件热重载回退 + 整体 git revert + 0.56 仍解析 .conf 的三层回滚路径已写清。

### weak verification

- 无。渲染检查 → `luac -p` 语法检查 → axiom build → 部署后日志确认，链路完整；azaram/ramen 仅静态验证已明确声明为 non-goal。

### scope ambiguity

- 发现 1 项真实缺口并已修正：`hosts/axiom/default.nix` 的 `extraConfig`（render.cm_enabled=false 的 DPMS/resume 防护、allow_session_lock_restore、no_hardware_cursors）初始未列入消费者清单。已将 axiom 加入 rfc.md Context、Decision 与 plan.md Scope。

### missing alternatives for meaningful trade-offs

- 无。三个选项各有取舍说明；`extraConfig` 语义变更（hyprlang → Lua）的风险已作为 Option A 的 cons 明示，三个消费者均在本仓库内一次转换。

## Findings

1. **[blocking, fixed]** axiom host extraConfig 遗漏 → 已折回 rfc.md 与 plan.md scope。
2. **[suggestion, accepted]** `hyprctl reload config-only` 是否仍被 0.56 接受列为 Open Question，部署时若报错则降级为 `hyprctl reload`——不阻塞，保留为运行时决策。

## Conclusion

设计可以通过门禁；修正已折回 rfc.md，plan.md 的 Design Index 指向 rfc.md 为真源。进入实现阶段（git-worktree-pr envelope + engineer）。
