# Axiom Build And Caelestia Regression

## Metadata

- `task-id`: `axiom-build-caelestia-regression`
- `status`: `active`
- `risk`: `low`
- `schema-version`: `current`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Outcome Summary

- Axiom build gate was restored without allowing insecure packages: Vesktop's temporary `pnpm_10_29_2` pin is conditionally replaced by `pkgs.unstable.pnpm_10`, and Axiom Docker uses Docker 29 through a module package option.
- The Caelestia startup regression was traced to `hey hook startup` failing before Caelestia ran because the managed Janet JPM tree contained native modules compiled for an older Janet ABI.
- The terminal font regression was traced to Foot's configured `FiraCode Nerd Font Mono` not being available to the NixOS fontconfig package set, causing font fallback to a Chinese font.
- Current fix direction is minimal: rebuild managed JPM artifacts when the Janet version changes, and expose the terminal font package through `fonts.packages` when Foot is enabled.

## Reusable Decisions

- Do not use `permittedInsecurePackages` for Axiom package-set drift when a scoped package override or newer package selection fixes evaluation.
- `hey` startup hook reliability depends on the managed JPM tree matching the active Janet ABI; module-owned activation should rebuild that tree on Janet version changes.
- Terminal font ownership remains `modules.desktop.term.font`; terminal modules that rely on fontconfig should make the configured font package visible to the system font set.

## Related Raw Sources

- `plan`: `.legion/tasks/axiom-build-caelestia-regression/plan.md`
- `log`: `.legion/tasks/axiom-build-caelestia-regression/log.md`
- `tasks`: `.legion/tasks/axiom-build-caelestia-regression/tasks.md`
- `test-report`: `.legion/tasks/axiom-build-caelestia-regression/docs/test-report.md`
- `review-change`: `.legion/tasks/axiom-build-caelestia-regression/docs/review-change.md`
- `report`: `.legion/tasks/axiom-build-caelestia-regression/docs/report-walkthrough.md`
