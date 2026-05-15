## Summary

- Route `SUPER+SHIFT+Return` through `foot -e tmux new-session -A -s main` so the shortcut creates or restores the fixed `main` tmux session.
- Keep global terminal behavior unchanged for `TERMINAL`, `$terminal`, and `$taskManager`.
- Add Legion task evidence for contract, verification, review, and walkthrough.

## Test Plan

- `nix eval --raw '.#nixosConfigurations.axiom.config.home.configFile."hypr/custom/keybinds.conf".text'`
- `nix eval --raw '.#nixosConfigurations.axiom.config.home.configFile."hypr/custom/env.conf".text'`
- `nix eval --raw '.#nixosConfigurations.axiom.config.home.configFile."hypr/custom/variables.conf".text'`
- `git diff --check`

## Legion Evidence

- `.legion/tasks/foot-tmux-hotkey/plan.md`
- `.legion/tasks/foot-tmux-hotkey/docs/test-report.md`
- `.legion/tasks/foot-tmux-hotkey/docs/review-change.md`
- `.legion/tasks/foot-tmux-hotkey/docs/report-walkthrough.md`
