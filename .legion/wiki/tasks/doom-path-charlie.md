# Charlie Doom Emacs PATH

## Metadata

- `task-id`: `doom-path-charlie`
- `status`: `active`
- `risk`: `low`
- `schema-version`: `current`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Outcome Summary

`charlie` uses a directly installed `/Applications/Emacs.app` rather than the repository's Nix Emacs module. Doom's CLI wrapper already exists under `$XDG_CONFIG_HOME/emacs/bin`, but neither that directory nor Emacs.app's CLI shim directory was present in generated zsh PATH.

The current fix prepends both `$XDG_CONFIG_HOME/emacs/bin` and `/Applications/Emacs.app/Contents/MacOS/bin` through `modules.shell.zsh.envInit` in `hosts/charlie/default.nix`. This keeps `modules.editors.emacs.enable` disabled and only repairs command lookup for interactive zsh sessions.

Validation proved the changed Nix file parses and the charlie Darwin config generates a `.config/zsh/.zshenv` containing the new PATH block.

## Reusable Decisions

- For direct macOS app installs, prefer explicit shell PATH wiring for app-provided CLI shims over enabling a Nix module that would change the installation source.
- For Doom Emacs on charlie, shell lookup requires both the Doom bin directory and the direct Emacs.app shim directory.
- Validate PATH fixes against generated shell env content, not only against source diff.

## Related Raw Sources

- `plan`: `.legion/tasks/doom-path-charlie/plan.md`
- `log`: `.legion/tasks/doom-path-charlie/log.md`
- `tasks`: `.legion/tasks/doom-path-charlie/tasks.md`
- `test-report`: `.legion/tasks/doom-path-charlie/docs/test-report.md`
- `review-change`: `.legion/tasks/doom-path-charlie/docs/review-change.md`
- `render-handoff`: `.legion/tasks/doom-path-charlie/docs/render-handoff.md`
- `report`: `.legion/tasks/doom-path-charlie/docs/report-walkthrough.md`
- `pr-body`: `.legion/tasks/doom-path-charlie/docs/pr-body.md`

## Notes

- Runtime deployment still requires applying the charlie nix-darwin configuration.
- HTML walkthrough render handoff is artifact-only/blocker because this repo has no existing Pages PR preview workflow and adding one is outside this task scope.
