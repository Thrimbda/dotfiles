# axiom-sidra-apple-music

## Metadata

- `task-id`: `axiom-sidra-apple-music`
- `status`: `completed`
- `risk`: `low`
- `schema-version`: `2026-05-16`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Outcome Summary

Sidra is now declaratively installed for the `axiom` workstation as the preferred Apple Music desktop client. The root flake tracks `github:wimpysworld/sidra`, the package is exposed through a small `modules.desktop.apps.sidra` module, and `axiom` enables that module. The `axiom` system toplevel builds successfully with Sidra in the closure.

## Reusable Decisions

- For Sidra, use the upstream flake package directly instead of wrapping an AppImage locally or using Cider.
- Keep Sidra package-only in this repository: install the desktop client declaratively, but do not claim Apple Music login/playback state or Widevine runtime behavior without a live graphical-session smoke test.
- When adding a new flake-sourced GUI package module, stage the new module before Nix validation so the Git-backed flake source includes it.

## Related Raw Sources

- `plan`: `.legion/tasks/axiom-sidra-apple-music/plan.md`
- `log`: `.legion/tasks/axiom-sidra-apple-music/log.md`
- `tasks`: `.legion/tasks/axiom-sidra-apple-music/tasks.md`
- `test-report`: `.legion/tasks/axiom-sidra-apple-music/docs/test-report.md`
- `review`: `.legion/tasks/axiom-sidra-apple-music/docs/review-change.md`
- `report`: `.legion/tasks/axiom-sidra-apple-music/docs/report-walkthrough.md`

## Notes

- Verification covered option evaluation, dry-run toplevel evaluation, and actual `nix build --no-link` of the `axiom` system toplevel.
- Runtime Apple Music authentication and playback remain post-switch graphical-session smoke checks.
