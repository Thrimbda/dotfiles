# Report Walkthrough

Mode: implementation

## What Changed

- `modules/desktop/hyprland.nix` now routes `SUPER+SHIFT+Return` through `tmuxTerminalCommand`.
- The generated command is `foot -e tmux new-session -A -s main`, which creates or attaches the fixed `main` tmux session.
- The keyboard shortcut help text now describes the shortcut as opening a tmux terminal.

## Why

The previous shortcut launched a plain terminal shell. The requested behavior is for the high-frequency terminal hotkey to recover the persistent tmux workspace when it exists, or create it when it does not.

## Scope Boundaries

- Global `TERMINAL` behavior stays unchanged.
- The `$terminal` variable stays unchanged.
- The `$taskManager` terminal command stays unchanged.
- Foot and tmux configuration files are not modified.

## Verification

Evidence: `docs/test-report.md`

- Evaluated generated `axiom` `hypr/custom/keybinds.conf`.
- Confirmed the keybind emits `foot -e tmux new-session -A -s main`.
- Evaluated `env.conf` and `variables.conf` to confirm unrelated terminal paths did not drift.
- Ran `git diff --check` with no whitespace errors.

## Review

Evidence: `docs/review-change.md`

- Verdict: PASS.
- Blocking findings: none.
- Security trigger: none.

## Operator Note

After deployment, reload or restart the managed Hyprland config so the generated keybind is applied to the live session.
