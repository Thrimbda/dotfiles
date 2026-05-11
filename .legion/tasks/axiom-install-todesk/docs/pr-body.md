## Summary

- Install ToDesk on `axiom` by adding `pkgs.todesk` to the host-local `user.packages` list.
- Keep the change package-only; no daemon, service, firewall, or live-system switch changes are included.
- Add Legion evidence for contract, verification, review, and walkthrough.

## Verification

- `nix eval` confirmed pinned `pkgs.todesk` is `todesk-4.7.2.0`, `meta.broken = false`, and supports `x86_64-linux`.
- `nix eval` confirmed `flake.nixosConfigurations.axiom.config.user.packages` contains `todesk` and produces a toplevel derivation path.

## Notes

- `nixos-rebuild switch` was intentionally skipped per task constraint.
- Runtime ToDesk behavior remains to be checked after applying the new axiom system configuration.
