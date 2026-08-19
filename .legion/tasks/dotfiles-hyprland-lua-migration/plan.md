# Dotfiles Hyprland Conf to Lua Migration

## Task Identity

- Name: Dotfiles Hyprland Conf to Lua Migration
- Task ID: `dotfiles-hyprland-lua-migration`
- Risk: medium — generated desktop config format migration across module + theme + hosts, rollback-able via git revert

## 目标

Eliminate the Hyprland `.conf` deprecation warning and prepare the desktop for Hyprland 0.57 by migrating the generated Hyprland configuration from hyprlang `.conf` to Lua `hyprland.lua` using the `hl.*` API.

## 问题陈述

Hyprland 0.55 deprecated hyprlang config, 0.56.1 warns at startup that `.conf` will be removed in 0.57. The repo generates Hyprland config from `modules/desktop/hyprland.nix` (env, execs, general, rules, keybinds, workspaces, monitors), roots it at `config/hypr/hyprland.conf`, and accepts hyprlang `extraConfig` from the autumnal theme and hosts azar/ramen. Without migration the desktop breaks when unstable Hyprland reaches 0.57.

## 验收标准

- [ ] `config/hypr/hyprland.conf` is removed and replaced by `config/hypr/hyprland.lua` that requires the generated module files.
- [ ] All Nix-generated Hyprland configFile entries are `.lua` (env, execs, general, rules, keybinds, workspaces, monitors) and use the `hl.*` Lua API; no `.conf` remains in the Hyprland config path.
- [ ] `modules.desktop.hyprland.extraConfig` is documented to carry Lua and all its users (autumnal theme, hosts azar, hosts ramen) are converted to valid Lua.
- [ ] `hypridle.conf` stays untouched (hypridle still uses hyprlang).
- [ ] Rendered Lua files pass syntax check and the axiom closure builds; static evidence recorded in docs.
- [ ] After deploy to axiom, live session reloads with no `.conf` deprecation warning; startup hooks and keybinds still work.
- [ ] Work delivered via PR in an isolated worktree; `.legion/wiki` closeout updated.

## 假设 / 约束 / 风险

- **假设**: nixos-unstable Hyprland is >= 0.55 (currently 0.56.x) and loads `~/.config/hypr/hyprland.lua`; Lua API follows the official wiki.
- **假设**: Hyprland `require()` resolves relative to `hyprland.lua`, each required file is a separate scope, and the files always exist when the module is enabled, so plain `require` is safe.
- **假设**: Home Manager removes obsolete managed `.conf` symlinks on activation.
- **假设**: `hyprctl reload` / `reload config-only` and `hyprctl keyword` runtime dispatches work unchanged with Lua config.
- **假设**: `hl.on("hyprland.start")` handlers run in registration order, preserving the old exec ordering (`hey hook startup` before xrandr primary).
- **假设**: Deferred approval — the user instructed to continue without further questions; the recommended path, boundaries, and non-goals below are the locked contract and PR merge is the approval vehicle.
- **约束**: Drop variable indirection: inline Nix-computed values into generated Lua; delete `custom/variables.conf` instead of emulating `$var` semantics.
- **约束**: Preserve require order env, execs, general, rules, keybinds, workspaces, monitors so startup handler registration order matches the old source order.
- **约束**: Do not modify Caelestia source, `hypridle.conf`, `uwsm/env`, monitor hotplug scripts, or keybinding help text.
- **约束**: Axiom builds must run on Axiom; never build the Acorn closure on Acorn.
- **约束**: Implementation happens in an isolated git worktree and is delivered via PR.
- **风险**: Lua syntax errors in a generated file break config reload for that file; mitigated by syntax-checking rendered files before deploy.
- **风险**: Handler ordering is an assumption; verify `hey hook startup` still runs first after deploy.
- **风险**: Dispatcher argument shapes differ from hyprlang (e.g. fullscreen mode/action); verify keybind behavior after deploy.
- **风险**: Azar/Ramen hosts are not deployed in this task; their conversions get static validation only.
- **风险**: Live reload on axiom during an active session can briefly break binds if a file errors; build first, then reload, with a documented rollback path.

## 要点

- This is a mechanical format translation with a well-defined mapping (hyprlang → `hl.*`), not a behavior redesign: same binds, same rules, same startup order.
- `hypridle.conf`, uwsm env, and runtime `hyprctl keyword` monitor hotplug paths stay in hyprlang/unchanged because those components are not Hyprland's own config.
- The `extraConfig` option changes meaning (hyprlang lines → Lua code); its three users are converted in the same change.
- `$var` indirection has no Lua equivalent; all generated values are inlined from Nix.

## 范围

- `config/hypr/hyprland.conf` → `config/hypr/hyprland.lua`
- `modules/desktop/hyprland.nix` generated configFile entries
- `modules/themes/autumnal/hyprland.nix` extraConfig
- `hosts/axiom/default.nix`, `hosts/azar/default.nix`, `hosts/ramen/default.nix`, `hosts/udon/default.nix` extraConfig
- `.legion/tasks/dotfiles-hyprland-lua-migration/**`
- `.legion/wiki/**` closeout entries

## Non-Goals / Out of Scope

- Do not migrate `hypridle.conf` or any other Hypr ecosystem tool config.
- Do not change monitor hotplug reconciling, Caelestia, uwsm env, or keybinding help content.
- Do not pin Hyprland to 0.56.
- Do not redesign keybindings, workspace numbering, or application placement rules.
- Do not live-deploy to azar/ramen/harusame/udon/atlas hardware in this task.

## 设计索引 (Design Index)

> **Design Source of Truth**: `docs/rfc.md`

**摘要**:
- Map hyprlang to Lua API: `source` → `require`, `monitor` → `hl.monitor`, `env` → `hl.env`, `exec-once` → `hl.on("hyprland.start")` + `hl.exec_cmd`, `windowrule`/`layerrule` → `hl.window_rule`/`hl.layer_rule`, workspace rules → `hl.workspace_rule`, `bind`/`bindl`/`bindr`/`bindm` → `hl.bind` with `locked`/`release`/`mouse` flags, category blocks → `hl.config`.
- `extraConfig` carries Lua appended to `custom/general.lua`; convert autumnal, azar, ramen.
- Inline host facts into generated Lua; remove `custom/variables.conf`.
- Verify: render generated files, `luac -p` syntax check, build axiom closure, then live reload with warning-free confirmation.

## 阶段概览

1. **Brainstorm** - Materialize the migration contract (this document).
2. **Spec RFC** - Write `docs/rfc.md`: mapping table, file-by-file conversion sketch, verification strategy, rollback plan.
3. **Review RFC** - Adversarial design review to PASS.
4. **Engineer** - Implement in an isolated worktree (git-worktree-pr envelope).
5. **Verify Change** - Render + syntax-check generated Lua, build axiom closure, record evidence.
6. **Review Change** - Assess delivery readiness and scope boundaries.
7. **Report Walkthrough** - Reviewer-facing summary and PR body.
8. **Legion Wiki** - Task summary, decisions, and maintenance notes.

---

*创建于: 2026-08-19 | 最后更新: 2026-08-19*
