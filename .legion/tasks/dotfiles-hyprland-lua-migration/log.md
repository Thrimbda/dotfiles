# Dotfiles Hyprland Conf to Lua Migration - 日志

## 会话进展 (2026-08-19)

### ✅ 已完成

- Brainstorm: contract materialized in plan.md/tasks.md with deferred approval recorded (user instructed to continue without further questions; PR merge is the approval vehicle).
- Spec RFC: docs/rfc.md written (Standard RFC profile, medium risk) — Options/Decision/Verification/Rollback; axiom extraConfig consumer gap found in review and folded back.
- Review RFC: docs/review-rfc.md PASS with corrections folded in.
- Engineer: implemented in worktree `.worktrees/dotfiles-hyprland-lua-migration` (base origin/master @1307a9fb, branch `legion/dotfiles-hyprland-lua-migration-hyprland-lua`).
  - Root `config/hypr/hyprland.lua` requires env/execs/general/rules/keybinds/workspaces/monitors in the old source order.
  - Generated `custom/{env,execs,general,rules,keybinds}.lua`, `workspaces.lua`, `monitors.lua`; `custom/variables.conf` removed.
  - extraConfig → Lua for axiom, azar, ramen, udon (found during review scan), and the autumnal theme.
- Verify: nix parse (5 files), rendered all generated Lua for axiom/azar/ramen/udon, `luac -p` PASS on 12 files, `nixos-rebuild build --flake .#axiom` PASS; built home-manager-files shows no `.conf` left except hypridle.conf/xdph.conf. Evidence: docs/test-report.md.
- Review Change: docs/review-change.md PASS; scope clean; security lens evaluated (no triggers).
- Report Walkthrough: docs/report-walkthrough.md (implementation mode) + docs/pr-body.md.
- Git lifecycle: PR #167 created from worktree branch, squash-merged into master (91f46760). No required checks on the branch. Worktree removed. Main worktree refreshed to origin/master via `git reset --mixed origin/master` (detached HEAD, matching the pre-existing detached state) with other sessions' WIP and the local hosts/axiom disk-label edit preserved.
- Wiki writeback + task closeout in progress via closeout branch `legion/dotfiles-hyprland-lua-migration-closeout`.

### 🟡 进行中

- Closeout PR for wiki writeback + task closeout docs + ledger rows.

### ⚠️ 阻塞/待定

- Live deploy smoke on axiom (post-merge): switch + `hey reload`, confirm warning gone and startup order; see docs/test-report.md residual list.

---

## 关键文件

- `.legion/tasks/dotfiles-hyprland-lua-migration/plan.md`, `tasks.md`
- `docs/rfc.md`, `docs/review-rfc.md`, `docs/test-report.md`, `docs/review-change.md`, `docs/report-walkthrough.md`, `docs/pr-body.md`
- Changed code: `config/hypr/hyprland.lua`, `modules/desktop/hyprland.nix`, `modules/themes/autumnal/hyprland.nix`, `hosts/{axiom,azar,ramen,udon}/default.nix`

---

## 关键决策

| 决策 | 原因 | 替代方案 | 日期 |
|------|------|----------|------|
| Migrate to Lua `hl.*` config now (Option A) | 0.57 removes .conf; layered require structure preserves module architecture | monolithic single lua file; pin 0.56 | 2026-08-19 |
| Drop `custom/variables.conf`, inline Nix values | Lua has no $var equivalent; Nix computes all values at build time | returned-table modules (risk: require wrapper may not preserve return values) | 2026-08-19 |
| Keep `extraConfig` option name, change semantics to Lua | only 4 host consumers + 1 theme, all converted in-repo | new option name (churn without benefit) | 2026-08-19 |
| udon added to scope during implementation review | keyword scan found remaining hyprlang extraConfig | n/a (scope gap; converted) | 2026-08-19 |

---

## 快速交接

**下次继续从这里开始：**

1. Merge the wiki/closeout PR (auto-merge enabled if repo policy allows; the implementation PR merged with no required checks).
2. Post-merge deploy smoke on axiom: `nixos-rebuild switch --flake .#axiom`, then `hey reload`; verify no `.conf` deprecation warning in the Hyprland log, `hyprland-session.target` active, and spot-check binds (fullscreen, mouse drag/resize, workspaces 1..20).
3. If `hyprctl reload config-only` is rejected on 0.56, change the `95-hyprland` reload hook to plain `hyprctl reload`.

**注意事项：**

- Main worktree keeps a local `hosts/axiom/default.nix` disk-label WIP owned by another session; do not overwrite it.
- Rollback of the whole change: revert merge commit 91f46760 and rebuild; Hyprland 0.56 still parses `.conf` (sources recover from git history).
- Repo rule: never build the Acorn closure on Acorn; axiom builds run on Axiom.

---

*最后更新: 2026-08-19*
