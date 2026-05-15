# foot-tmux-hotkey

## Metadata

- `task-id`: `foot-tmux-hotkey`
- `status`: `completed`
- `risk`: `low`
- `schema-version`: `2026-05-15`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Outcome Summary

- `SUPER+SHIFT+Return` on Axiom now opens the configured terminal with `tmux new-session -A -s main`.
- The hotkey restores the fixed `main` tmux session when it exists, or creates it when it does not.
- The global terminal defaults stay plain: `TERMINAL`, `$terminal`, and task-manager terminal launch behavior were intentionally left unchanged.
- Verification used targeted Nix evaluation of generated Hyprland config and confirmed the keybind and unchanged terminal variables.

## Reusable Decisions

- For a tmux-first terminal hotkey, scope the behavior to that generated keybind instead of wrapping every terminal launch in tmux.
- Keep the shortcut reference modal text in sync when generated Hyprland keybind behavior changes.

## Related Raw Sources

- `plan`: `.legion/tasks/foot-tmux-hotkey/plan.md`
- `log`: `.legion/tasks/foot-tmux-hotkey/log.md`
- `tasks`: `.legion/tasks/foot-tmux-hotkey/tasks.md`
- `test-report`: `.legion/tasks/foot-tmux-hotkey/docs/test-report.md`
- `review`: `.legion/tasks/foot-tmux-hotkey/docs/review-change.md`
- `report`: `.legion/tasks/foot-tmux-hotkey/docs/report-walkthrough.md`

## Notes

- Live use still requires deploying/reloading the generated Hyprland config on Axiom.
