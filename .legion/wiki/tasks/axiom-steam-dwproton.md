# axiom-steam-dwproton

## Metadata

- `task-id`: `axiom-steam-dwproton`
- `status`: `active`
- `risk`: `low`
- `schema-version`: `legion-wiki`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Outcome Summary

This task adds a repository-pinned DWProton integration for Steam and enables it only on Axiom. The current effective shape is an opt-in Steam module option, `modules.desktop.apps.steam.dwproton.enable`, which appends the locked DWProton package to `programs.steam.extraCompatPackages` when enabled. Repository validation proves Axiom evaluates and builds with `dwproton-11.0-4`, while Azar remains disabled with no extra compatibility packages. Live Steam UI selection remains a post-deploy smoke check, not a checked-in compatibility claim.

## Reusable Decisions

- External Steam compatibility tools should be wired through `programs.steam.extraCompatPackages`, not by changing Steam runtime, Gamescope, MangoHud, Proton-GE, or per-game launch options.
- Compatibility tools that are not intended for every host should stay behind module-level opt-in options defaulting to false.
- Validation should prove both the opted-in host package list and a representative non-opt-in host's default behavior.

## Related Raw Sources

- `plan`: `.legion/tasks/axiom-steam-dwproton/plan.md`
- `log`: `.legion/tasks/axiom-steam-dwproton/log.md`
- `tasks`: `.legion/tasks/axiom-steam-dwproton/tasks.md`
- `test-report`: `.legion/tasks/axiom-steam-dwproton/docs/test-report.md`
- `review`: `.legion/tasks/axiom-steam-dwproton/docs/review-change.md`
- `report`: `.legion/tasks/axiom-steam-dwproton/docs/report-walkthrough.md`
