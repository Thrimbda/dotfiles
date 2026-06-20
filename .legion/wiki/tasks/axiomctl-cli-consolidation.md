# axiomctl-cli-consolidation

## Metadata

- `task-id`: `axiomctl-cli-consolidation`
- `status`: `historical`
- `risk`: `medium`
- `schema-version`: `2026-06-legion-wiki`
- `historical`: `true`
- `supersedes`: `axiom-mode-clean-cli`
- `superseded-by`: `c1ctl-hey-rust-migration`

## Outcome Summary

This historical task renamed the Axiom host-local Rust CLI from `axiom-mode` to `axiomctl` and intentionally kept the command surface narrow. It has been superseded by `c1ctl-hey-rust-migration`, which makes `c1ctl` the durable Rust control CLI and begins the staged non-Rofi Rust migration of `hey`.

The details below are historical context for why the prior narrow `axiomctl` boundary existed. Current package naming and command ownership live in `packages/c1ctl` and the `c1ctl-hey-rust-migration` summary.

## Reusable Decisions

- Historical only: `axiomctl` was the Axiom host-control CLI name before `c1ctl` superseded it.
- Keep privileged mode switching behind fixed enum branches and fixed systemd target names.
- Historical only: `axiomctl reload` was a narrow fixed-argv bridge to `hey reload`.
- Current Rofi and dynamic dispatch boundaries are defined by `c1ctl-hey-rust-migration`.

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
- This summary is retained as historical context; do not use it as current CLI truth.
