# Axiom Antigravity Install

## Metadata

- `task-id`: `axiom-antigravity-install`
- `status`: `active`
- `risk`: `low`
- `schema-version`: `current`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Outcome Summary

This task installs Google Antigravity on the `axiom` NixOS host through the declarative dotfiles configuration. The implementation adds `unstable.antigravity-fhs` to the existing host-local `user.packages` list in `hosts/axiom/default.nix`.

The current effective conclusion is package-only installation through the repository's existing `pkgs.unstable` overlay and `allowUnfree` setup. No third-party Antigravity flake, manual download, `nix profile install`, account state, extension setup, token, proxy, sync, or GUI runtime configuration is part of this task.

Verification confirms the merged axiom user package list contains `antigravity`, the selected FHS package builds from the current lock, and the axiom toplevel dry-run includes Antigravity derivations. The current locked Antigravity package version is `1.15.8`.

## Reusable Decisions

- For one-off host-specific GUI client installation on `axiom`, prefer the host-local `user.packages` list over a reusable module unless runtime policy, service integration, cross-host enablement, or generated config is required.
- For unfree or FHS-wrapped GUI packages from `pkgs.unstable`, validate the evaluated host user package list, the package build itself, and the host toplevel dry-run; do not treat GUI login/runtime behavior as covered unless explicitly scoped.

## Related Raw Sources

- `plan`: `.legion/tasks/axiom-antigravity-install/plan.md`
- `log`: `.legion/tasks/axiom-antigravity-install/log.md`
- `tasks`: `.legion/tasks/axiom-antigravity-install/tasks.md`
- `test-report`: `.legion/tasks/axiom-antigravity-install/docs/test-report.md`
- `review`: `.legion/tasks/axiom-antigravity-install/docs/review-change.md`
- `walkthrough`: `.legion/tasks/axiom-antigravity-install/docs/report-walkthrough.md`
- `pr-body`: `.legion/tasks/axiom-antigravity-install/docs/pr-body.md`

## Notes

- After this branch is applied to `axiom`, run the usual host switch and launch Antigravity manually to confirm GUI startup and any Google account flow.
- Updating Antigravity beyond the currently locked `1.15.8` package should be a separate nixpkgs lock/update task.
