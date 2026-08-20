# axiom-nix-warning-migration

## Metadata

- `task-id`: `axiom-nix-warning-migration`
- `status`: `completed`
- `risk`: `medium`
- `schema-version`: `current`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Outcome Summary

The Axiom NixOS warning migration replaces deterministic repository-owned deprecated references and system-path collisions without globally suppressing diagnostics. GTK4 now uses the selected null theme, Linux Info documentation defaults to disabled, and the root flake retains only declared Darwin platforms. The focused Bluetooth test fixture uses explicit boot and resume services; production Bluetooth behavior was not changed.

## Reusable Decisions

- Classify cache transport and upstream package diagnostics separately from repository-owned evaluation and collision warnings; migrate the latter at their source.
- Preserve wrapper behavior while resolving collisions by assigning each binary one package owner.
- Replace deprecated test hooks with explicitly ordered systemd fixtures and assert on the node that actually enables the fixture.

## Related Raw Sources

- `plan`: `.legion/tasks/axiom-nix-warning-migration/plan.md`
- `log`: `.legion/tasks/axiom-nix-warning-migration/log.md`
- `tasks`: `.legion/tasks/axiom-nix-warning-migration/tasks.md`
- `rfc`: `.legion/tasks/axiom-nix-warning-migration/docs/rfc.md`
- `review`: `.legion/tasks/axiom-nix-warning-migration/docs/review-change.md`
- `verification`: `.legion/tasks/axiom-nix-warning-migration/docs/test-report.md`
- `report`: `.legion/tasks/axiom-nix-warning-migration/docs/report-walkthrough.md`
