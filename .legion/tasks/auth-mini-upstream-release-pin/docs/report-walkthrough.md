# Report Walkthrough

Mode: implementation.

## Change

- Updated `packages/auth-mini/default.nix` from `latest-2026-07-10` to `latest-2026-07-12`.
- Replaced the fixed-output hash with `sha256-OFLkVvKkVrai+Mv22Rhlmq2SVv+Gw6Py6sKhonCZsVk=`.
- No service, gateway, secret, nginx, database, port, or deployment configuration changed.

## Design Gate

No RFC was produced, by explicit user request. The plan bounds this to a two-line production pin update and makes deployment redesign a non-goal.

## Verification

- `git diff --check` — PASS.
- `nix build --no-link .#packages.x86_64-linux.auth-mini` — PASS; produced `/nix/store/y5ap29r9x0baqmcfj93rbblyx985mx2r-auth-mini-latest-2026-07-12`.
- `nix build --no-link .#nixosConfigurations.acorn.config.system.build.toplevel` — PASS; produced `/nix/store/b9a7f42kja84whcb7pwsgsz6xglndgci-nixos-system-acorn-25.11.20260630.b6018f8`.
- Recorded evaluation returned version `latest-2026-07-12` and the configured hash; the Acorn service references the updated package in the built toplevel closure.
- The GitHub release asset digest and independent URL prefetch matched the configured hash for the release workflow associated with upstream merge `9560660a51ee0e0b0a538e36c0b2883b16281eff`.

## Review

PASS. `docs/review-change.md` reports no blocking correctness, scope, maintainability, or security findings and marks the change ready for delivery and PR merge.

## Bounded Risk

The existing mutable `latest` URL remains unchanged. Its fixed-output hash causes future upstream drift to fail closed.
