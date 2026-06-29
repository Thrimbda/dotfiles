# Report Walkthrough

Mode: implementation.

## What Changed

- Moved the Autumnal zsh prompt from `modules/themes/autumnal/config/zsh/prompt.zsh` to `config/zsh/prompt.zsh` and source it from `config/zsh/.zshrc`.
- Moved the Autumnal tmux theme from `modules/themes/autumnal/config/tmux.conf` to `config/tmux/theme.conf` and source it from `config/tmux/tmux.conf`.
- Removed the obsolete `autumnal-cli` theme module and its orphaned shell/tmux assets.
- Added `modules.desktop.term.font` defaults in `modules/desktop/term/default.nix` and published `hey.info.term.font`.
- Updated Foot to consume `modules.desktop.term.font` and install the configured terminal font package when Foot is enabled.
- Removed `modules.theme.fonts.terminal` and Autumnal terminal font overrides from the theme layer.
- Updated Hyprland helper scripts to read terminal font data from `hey info term font`.
- Simplified Darwin theme support so it no longer dynamically injects theme-owned zsh/tmux files.

## Why

The theme layer was acting as a cross-module wiring point for shell and terminal defaults. This change moves shell prompt, tmux theme, and terminal font defaults into their owning config/modules while leaving GTK, wallpaper, Rofi, Hyprland visual, Doom, and theme path responsibilities untouched for later work.

## Key Files

- `config/zsh/.zshrc`
- `config/zsh/prompt.zsh`
- `config/tmux/tmux.conf`
- `config/tmux/theme.conf`
- `modules/desktop/term/default.nix`
- `modules/desktop/term/foot.nix`
- `modules/themes/default.nix`
- `modules/themes/autumnal/default.nix`
- `modules/themes/darwin.nix`
- `config/hypr/bin/get-font.zsh`
- `config/hypr/bin/open-term.zsh`

## Verification

Evidence is recorded in `docs/test-report.md`.

- PASS: residual search for old `fonts.terminal` and `hey info theme fonts terminal` references.
- PASS: orphan check for theme-owned shell/tmux assets; all tracked theme shell/tmux config assets are deleted in this diff and no matching worktree files remain.
- PASS: Axiom terminal font info evaluates to `FiraCode Nerd Font Mono`, size `9.5`.
- PASS: Axiom generated Foot local config uses the new terminal-owned font.
- PASS: zsh syntax checks for `.zshrc`, moved prompt, and helper scripts.
- PASS: `git diff --check`.
- PASS: representative NixOS derivation evals for Axiom, Atlas, and Acorn.
- KNOWN FAIL: Darwin `charles` eval remains blocked by unrelated existing `programs.nix-ld` usage in `modules/dev/playwright.nix`.

## Review Result

Evidence is recorded in `docs/review-change.md`.

- PASS after re-review.
- No blocking findings.
- No security trigger detected.

## Residual Risks

- Default zsh/tmux appearance now applies to all hosts that enable zsh/tmux; this is intended by the scope but may affect host-specific UX.
- Hidden out-of-repo consumers of `modules.theme.fonts.terminal` could break.
- Darwin behavior is not fully validated until the unrelated nix-darwin `programs.nix-ld` issue is fixed.

## Follow-Ups Not In This PR

- Move GTK/cursor/fontconfig/wallpaper/Rofi/Hyprland/Doom theme responsibilities into owning modules in separate tasks.
- Clean up stale host `theme.useX` attributes separately.
- Consider a post-activation tmux smoke test after the repository config is deployed.
