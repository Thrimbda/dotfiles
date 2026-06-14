# dotfiles-flake-update-warning-cleanup

## Metadata

- `task-id`: `dotfiles-flake-update-warning-cleanup`
- `status`: `active`
- `risk`: `low-medium`
- `schema-version`: `2026-06-14`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Outcome Summary

- All flake inputs were updated with `nix flake update`.
- The updated `axiom` NixOS system build now succeeds without warning output on a cached rerun of `nix build .#nixosConfigurations.axiom.config.system.build.toplevel --no-link`.
- Compatibility fixes covered removed package attributes, renamed NixOS options, deprecated package references, insecure Docker 28, Nix app metadata, path-aware module scanning, and NixOS `pkgs` plumbing.
- `nix flake check --no-build` evaluates compatible outputs and all current-system NixOS hosts. Remaining warnings are limited to intentional custom flake outputs used by `hey` metadata queries.

## Reusable Decisions

- For broad flake updates, treat the target host's toplevel build as the decisive warning surface when the user specifically asks to clean `nix build` warnings.
- Do not silence insecure package failures with allowlists when a maintained package version exists; prefer the maintained package, as with Docker 29 replacing Docker 28.
- If `nixpkgs.pkgs` is supplied to NixOS configurations, pair it with nixpkgs `read-only.nix` and avoid module-level `nixpkgs.overlays` writes. Apply needed overlays during host `pkgs` construction instead.
- Keep repository-specific custom flake outputs such as `hostMetadata` when local tooling depends on them, even if `nix flake check` reports unknown-output warnings; document the distinction from the host build warning surface.

## Related Raw Sources

- `plan`: `.legion/tasks/dotfiles-flake-update-warning-cleanup/plan.md`
- `log`: `.legion/tasks/dotfiles-flake-update-warning-cleanup/log.md`
- `tasks`: `.legion/tasks/dotfiles-flake-update-warning-cleanup/tasks.md`
- `test-report`: `.legion/tasks/dotfiles-flake-update-warning-cleanup/docs/test-report.md`
- `review`: `.legion/tasks/dotfiles-flake-update-warning-cleanup/docs/review-change.md`
- `report`: `.legion/tasks/dotfiles-flake-update-warning-cleanup/docs/report-walkthrough.md`
