# Report Walkthrough: Axiom Sidra Apple Music

Mode: implementation.

## What Changed

- Added `github:wimpysworld/sidra` as a root flake input and pinned it in `flake.lock`.
- Added `modules/desktop/apps/sidra.nix` with `modules.desktop.apps.sidra.enable` and an optional package override.
- Enabled Sidra for the `axiom` workstation in `hosts/axiom/default.nix`.

## Why

Apple Music has no official native Linux desktop app. Sidra provides the requested Apple Music desktop experience while fitting this repository's existing declarative desktop app module pattern.

## Verification

- `nix eval .#nixosConfigurations.axiom.config.modules.desktop.apps.sidra.enable` returned `true`.
- `nix build --dry-run .#nixosConfigurations.axiom.config.system.build.toplevel` passed and showed Sidra derivations in the closure.
- `nix build --no-link .#nixosConfigurations.axiom.config.system.build.toplevel` passed and built the affected system toplevel.

See `docs/test-report.md` for full command evidence.

## Review Result

`docs/review-change.md` reports PASS with no blocking findings. The security lens was applied for the new external flake input; Sidra is lockfile-pinned and adds no services, secrets, firewall changes, or privilege rules.

## Residual Risk

Runtime Apple Music login/playback still depends on Apple's service and Sidra's upstream DRM/session behavior. This task only installs and enables Sidra declaratively.
