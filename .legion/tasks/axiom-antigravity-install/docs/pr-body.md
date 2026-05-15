## Summary

- Add Google Antigravity to axiom via `unstable.antigravity-fhs`.
- Keep the install declarative through the existing NixOS host config, without adding a new flake input or manual install path.
- Include Legion task evidence for contract, verification, and readiness review.

## Verification

- `nix eval --json .#nixosConfigurations.axiom.config.users.users.c1.packages --apply 'packages: builtins.filter (name: name == "antigravity" || name == "google-antigravity" || name == "antigravity-fhs" || name == "antigravity-1.15.8") (builtins.map (package: package.pname or package.name or "") packages)'`
- `nix build --no-link .#nixosConfigurations.axiom.pkgs.unstable.antigravity-fhs`
- `nix build --dry-run .#nixosConfigurations.axiom.config.system.build.toplevel`
- `git diff --check`

## Notes

- Current locked Antigravity version is `1.15.8`.
- GUI login/runtime validation is out of scope for this install-only change.
