# Theme Shell Terminal Migration

## Metadata

- `task-id`: `theme-shell-terminal-migration`
- `status`: `completed`
- `risk`: `low`
- `schema-version`: `legion-wiki-current`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Outcome Summary

- Shell prompt and tmux theme ownership moved out of `modules/themes` and into default `config/zsh` / `config/tmux` config paths.
- Terminal font ownership moved from `modules.theme.fonts.terminal` to `modules.desktop.term.font`, with Foot and runtime helper scripts consuming terminal-owned metadata.
- The remaining theme layer still owns GTK, wallpaper, colors, Rofi assets, Hyprland visual polish, Doom local theme, and `hey path theme` until separate scoped migrations provide safe owners.
- Representative Linux NixOS evals and shell syntax checks passed; Darwin eval remains blocked by an unrelated nix-darwin `programs.nix-ld` issue.

## Reusable Decisions

- Shell prompt and tmux theme assets should not be injected from active theme modules. Default shell/tmux appearance belongs in `config/zsh` and `config/tmux` unless a future task designs an explicit shell theme option.
- Terminal font policy belongs to `modules.desktop.term.font`; scripts should read `hey.info.term.font` instead of `hey.info.theme.fonts.terminal`.
- When reducing a theme module, delete both module wiring and orphaned theme-owned assets, then verify by path-level orphan checks as well as reference greps.

## Related Raw Sources

- `plan`: `.legion/tasks/theme-shell-terminal-migration/plan.md`
- `log`: `.legion/tasks/theme-shell-terminal-migration/log.md`
- `tasks`: `.legion/tasks/theme-shell-terminal-migration/tasks.md`
- `test-report`: `.legion/tasks/theme-shell-terminal-migration/docs/test-report.md`
- `review`: `.legion/tasks/theme-shell-terminal-migration/docs/review-change.md`
- `report`: `.legion/tasks/theme-shell-terminal-migration/docs/report-walkthrough.md`
- `pr-body`: `.legion/tasks/theme-shell-terminal-migration/docs/pr-body.md`

## Notes

- This task intentionally does not remove `modules/themes/default.nix`; remaining appearance responsibilities need their own owner modules or follow-up designs.
