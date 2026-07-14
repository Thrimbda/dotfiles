# Test Report

## Result

PASS. The package pin and consuming Acorn system closure build successfully.

## Evidence

- `git diff --check` passed.
- `nix build --no-link --print-out-paths --option substituters https://cache.nixos.org/ .#auth-mini-gateway` produced `/nix/store/khpsgxxa04bw6xi8v7b17x22ncm23abw-auth-mini-gateway-0.1.0-unstable-2026-07-13`.
- `nix build --no-link --print-out-paths --option substituters https://cache.nixos.org/ .#nixosConfigurations.acorn.config.system.build.toplevel` produced `/nix/store/5dfvwfn402c2l715lq0bwic3wnv8j3gq-nixos-system-acorn-25.11.20260630.b6018f8`.
- All four gateway service `ExecStart` values reference the new package.
- `nix why-depends` confirmed the Acorn toplevel reaches the new package through generated systemd units.

## Residuals

The first package build encountered an external `nix-community.cachix.org` TLS timeout. A bounded retry using the official Nix cache passed; this was not an implementation failure.
