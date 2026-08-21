# axiom-lock-dpms-plugin-fix

## Metadata

- `task-id`: `axiom-lock-dpms-plugin-fix`
- `status`: `active`
- `risk`: `medium`
- `schema-version`: `current`
- `historical`: `false`
- `supersedes`: `axiom-lock-dpms-delay` (plugin closure implementation only)
- `superseded-by`: `(none)`

## Outcome Summary

- The prior main-shell patch left Caelestia's separately built Config plugin unpatched, so QML and the runtime configuration schema came from different derivations.
- The correction splits Config C++ and shell QML patches by source fileset, patches the Config plugin directly, replaces the exact original plugin `buildInputs` entry by resolved store path, and exposes that same output through `passthru.plugin`.
- Clean source patching, configured package build, plugin `qmltypes`, exact dependency replacement, and shell closure checks pass; the old plugin is absent from the realized shell closure.
- Axiom deployment, live QML import selection, and the manual 60-second DPMS test are blocked because non-interactive sudo authentication requires a password. No switch, restart, or live lock test was attempted.

## Reusable Decisions

- A main Caelestia shell `overrideAttrs` does not propagate patches to its separately built Config plugin.
- Replace a plugin dependency by resolved store path with an exact-one-match assertion and update `passthru.plugin`; do not match names or append a second plugin.
- Treat source/build closure proof, deployed plugin import selection, and physical lock/DPMS behavior as separate evidence layers.

## Related Raw Sources

- `plan`: `.legion/tasks/axiom-lock-dpms-plugin-fix/plan.md`
- `log`: `.legion/tasks/axiom-lock-dpms-plugin-fix/log.md`
- `tasks`: `.legion/tasks/axiom-lock-dpms-plugin-fix/tasks.md`
- `rfc`: `.legion/tasks/axiom-lock-dpms-plugin-fix/docs/rfc.md`
- `test-report`: `.legion/tasks/axiom-lock-dpms-plugin-fix/docs/test-report.md`
- `reviews`: `.legion/tasks/axiom-lock-dpms-plugin-fix/docs/review-rfc.md`, `.legion/tasks/axiom-lock-dpms-plugin-fix/docs/review-change.md`
- `report`: `.legion/tasks/axiom-lock-dpms-plugin-fix/docs/report-walkthrough.md`
