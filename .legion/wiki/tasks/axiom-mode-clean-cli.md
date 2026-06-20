# axiom-mode-clean-cli

## Metadata

- `task-id`: `axiom-mode-clean-cli`
- `status`: `active`
- `risk`: `low`
- `schema-version`: `legion-wiki`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Outcome Summary

This follow-up replaces the first-pass inline `writeShellScriptBin` implementation of `axiom-mode` with a standalone no-dependency Rust package under `packages/axiom-mode`. The Axiom host now installs that package via `pkgs.callPackage ../../packages/axiom-mode {}` while keeping `axiom-cli.target` and the user-facing `cli` / `desktop` / `status` behavior unchanged.

## Reusable Decisions

- Host-local privileged control CLIs should not live as large inline shell strings inside host configs when they have durable behavior.
- Small fixed-command Rust CLIs are acceptable for system-control tools when they avoid runtime shell parsing and keep privileged argv fixed.
- Keep `axiom-mode` independent of `hey`; it is a sibling repository package, not a hook or `hey` subcommand.

## Related Raw Sources

- `plan`: `.legion/tasks/axiom-mode-clean-cli/plan.md`
- `log`: `.legion/tasks/axiom-mode-clean-cli/log.md`
- `tasks`: `.legion/tasks/axiom-mode-clean-cli/tasks.md`
- `test-report`: `.legion/tasks/axiom-mode-clean-cli/docs/test-report.md`
- `review`: `.legion/tasks/axiom-mode-clean-cli/docs/review-change.md`
- `report`: `.legion/tasks/axiom-mode-clean-cli/docs/report-walkthrough.md`
