# Theme Shell Terminal Migration

## Task Identity

- Name: Theme Shell Terminal Migration
- Task ID: `theme-shell-terminal-migration`
- Trigger: user requested submitting the completed `modules/themes` shell/terminal responsibility migration through Legion workflow.
- Base ref: `origin/master`

## Goal

Move shell prompt, tmux theme, and terminal font ownership out of `modules/themes` and into the default shell/terminal configuration owners, while keeping the remaining appearance responsibilities in the existing theme layer until they have safe owners.

## Problem

`modules/themes` currently owns responsibilities that are not really theme-selection concerns: zsh prompt sourcing, tmux theme sourcing, and Foot terminal font defaults. This makes the Autumnal theme module act as a cross-module wiring point and leaves runtime scripts dependent on `hey info theme fonts terminal`. The user wants these defaults merged into the owning zsh, tmux, and terminal configuration paths instead of remaining under a theme module.

## Acceptance Criteria

- Zsh prompt config is owned by default zsh config, not injected from `modules/themes/autumnal`.
- Tmux theme config is owned by default tmux config, not injected from `modules/themes/autumnal`.
- Terminal font defaults are owned by `modules.desktop.term.font` and consumed by Foot.
- Runtime terminal font scripts read `hey.info.term.font`, not `hey.info.theme.fonts.terminal`.
- `modules.theme.fonts.terminal` and Autumnal terminal overrides are removed.
- Existing theme responsibilities for GTK, wallpaper, Rofi, Hyprland visuals, Doom local theme, and `hey path theme` remain in place.
- Representative Nix evaluations and script syntax checks pass, with known unrelated Darwin blocker documented.

## Scope

- Move the Autumnal zsh prompt asset to `config/zsh/prompt.zsh` and source it from `config/zsh/.zshrc`.
- Move the Autumnal tmux theme asset to `config/tmux/theme.conf` and source it from `config/tmux/tmux.conf`.
- Add terminal font defaults under `modules/desktop/term/default.nix` and publish `hey.info.term.font`.
- Update `modules/desktop/term/foot.nix` to consume terminal-owned font settings and install the configured font package when Foot is enabled.
- Remove shell/tmux/terminal font responsibilities from `modules/themes/default.nix`, `modules/themes/autumnal/default.nix`, and `modules/themes/darwin.nix`.
- Delete the now-empty `modules/themes/autumnal-cli/default.nix` and its orphaned shell/tmux assets.
- Update Hyprland helper scripts that query the terminal font.
- Record verification, review, walkthrough, and PR evidence under this Legion task.

## Non-Goals

- Do not delete `modules/themes/default.nix` in this task.
- Do not move GTK, cursor, fontconfig, wallpaper, Rofi, Hyprland visual, Doom local theme, or theme sound path responsibilities yet.
- Do not remove host `theme.active` settings.
- Do not clean up stale `theme.useX` host attributes in this task.
- Do not submit `.opencode/plans/*.md` as project evidence.

## Assumptions

- The moved zsh and tmux assets are acceptable as default config for hosts that enable zsh/tmux.
- The current Autumnal terminal font is the desired default terminal font.
- Darwin evaluation may remain blocked by the existing unrelated `programs.nix-ld` option issue in `modules/dev/playwright.nix`.
- Remaining theme-layer responsibilities still require a later, separate appearance/Rofi/Hyprland migration design.

## Constraints

- Use the Legion worktree/PR lifecycle.
- Base the branch on latest `origin/master`.
- Keep changes scoped to shell/terminal ownership migration and task evidence.
- Preserve the main workspace local `.opencode` plan files and do not submit them.

## Risks

- Making prompt/tmux theme defaults may affect server hosts that enable zsh/tmux and previously used no theme-specific injection.
- Removing `modules.theme.fonts.terminal` can break any hidden consumer not found by repository search.
- `hey.info.term.font` must be present for runtime helper scripts before they are used.
- Darwin validation cannot be treated as clean until the pre-existing `programs.nix-ld` issue is fixed.

## Design Summary

- Use existing owning modules and config directories instead of introducing a new appearance abstraction in this task.
- Keep the theme layer as a compatibility boundary for GTK, wallpapers, colors, Rofi resources, and other appearance responsibilities.
- Publish terminal font information from the terminal module so scripts can depend on terminal ownership rather than theme metadata.
- Preserve behavior for Foot and desktop hosts through targeted Nix evaluations.

## Phases

- Brainstorm: materialize this Legion task contract from the approved OpenCode plan and existing implementation diff.
- Engineer: replay the scoped migration diff into the Legion worktree.
- Verify: run targeted search, Nix evals, zsh syntax checks, and diff checks.
- Review: assess readiness, regressions, scope, and residual risks.
- Report: produce reviewer-facing walkthrough and PR body.
- Wiki: write back durable task summary and any reusable patterns or maintenance notes.
- Git/PR: commit, rebase, push, open PR, attempt auto-merge, follow checks, then cleanup after terminal PR state.
