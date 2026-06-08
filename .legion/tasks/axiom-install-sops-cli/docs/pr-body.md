## Summary

- Add `sops` to `axiom`'s host-local `user.packages`.
- Keep this scoped to CLI availability only; no `sops-nix`, agenix, or secrets changes.

## Verification

- `nix eval --impure --raw .#nixosConfigurations.axiom.pkgs.sops.pname` -> `sops`
- `nix eval --impure --json .#nixosConfigurations.axiom.config.users.users.c1.packages --apply 'packages: builtins.any (pkg: (pkg.pname or "") == "sops") packages'` -> `true`
- `nix eval --impure --raw .#nixosConfigurations.axiom.config.system.build.toplevel.drvPath` -> generated toplevel `.drv`

## Notes

- `nix build --impure --dry-run .#nixosConfigurations.axiom.config.system.build.toplevel` was inconclusive due to remote cache HTTP 500 retries and the 120s tool timeout.
- After switching `axiom`, run `sops --version` as the live smoke check.
