# axiomctl-cli-consolidation

## Metadata

- `task-id`: `axiomctl-cli-consolidation`
- `status`: `active`
- `risk`: `medium`
- `schema-version`: `2026-06-legion-wiki`
- `historical`: `false`
- `supersedes`: `axiom-mode-clean-cli`
- `superseded-by`: `(none)`

## Outcome Summary

This task renames the Axiom host-local Rust CLI from `axiom-mode` to `axiomctl` and keeps the command surface intentionally narrow. The current durable entrypoint is `axiomctl mode cli`, `axiomctl mode desktop`, and `axiomctl mode status`, with top-level aliases for the common mode verbs. `axiomctl reload` is a fixed-argv bridge to the existing `hey reload` hook path, not a Rust replacement for `hey` dispatch.

The package now lives under `packages/axiomctl`, and the Axiom host installs it through `pkgs.callPackage ../../packages/axiomctl` with an injected `hey` path for reload. Broad Nix/dotfiles workflows, Rofi-era menus, and Caelestia-owned desktop controls remain outside this CLI.

## Reusable Decisions

- Use `axiomctl` as the Axiom host-control CLI name; reserve `hey` for broad dotfiles/Nix workflows and dynamic script dispatch.
- Keep privileged mode switching behind fixed enum branches and fixed systemd target names.
- Keep `axiomctl reload` as a narrow fixed-argv bridge to `hey reload` unless a future task explicitly redesigns hook ownership.
- Do not add Rofi-backed or user-script execution surfaces to `axiomctl`.

## Related Raw Sources

- `plan`: `.legion/tasks/axiomctl-cli-consolidation/plan.md`
- `log`: `.legion/tasks/axiomctl-cli-consolidation/log.md`
- `tasks`: `.legion/tasks/axiomctl-cli-consolidation/tasks.md`
- `test-report`: `.legion/tasks/axiomctl-cli-consolidation/docs/test-report.md`
- `review`: `.legion/tasks/axiomctl-cli-consolidation/docs/review-change.md`
- `report`: `.legion/tasks/axiomctl-cli-consolidation/docs/report-walkthrough.md`
- `pr-body`: `.legion/tasks/axiomctl-cli-consolidation/docs/pr-body.md`

## Notes

- Live target isolation and graphical reload remain post-deploy Axiom smoke checks.
- Historical raw docs for `axiom-cli-mode` and `axiom-mode-clean-cli` still mention `axiom-mode` as the prior implementation history.
