# Walkthrough: Install ToDesk on axiom

Mode: implementation
Date: 2026-05-11

## Change Summary

- Added `todesk` to `hosts/axiom/default.nix` under the existing host-local `user.packages` list.
- Kept the change package-only: no daemon, service, firewall, desktop-module, or live-system switch changes.
- Added Legion task evidence for contract, verification, review, and delivery.

## Evidence

- Contract: `.legion/tasks/axiom-install-todesk/plan.md`
- Verification: `.legion/tasks/axiom-install-todesk/docs/test-report.md`
- Review: `.legion/tasks/axiom-install-todesk/docs/review-change.md`

## Verification Result

- `pkgs.todesk` exists in the pinned nixpkgs input as `todesk-4.7.2.0` for `x86_64-linux` and is not marked broken.
- `axiom` configuration evaluation reports `hasTodesk = true` and produces a toplevel derivation path.
- `nixos-rebuild switch` was intentionally skipped by task constraint.

## Review Result

- PASS with no blocking findings.
- Security lens found no trust-boundary change because the diff only installs the package and does not configure remote access behavior.

## Residual Risk

- Runtime ToDesk launch/login behavior is not verified until the updated configuration is switched on axiom.
