# Test Report

## Result

PASS. The upstream release pin builds as an individual package and as part of the Acorn NixOS system closure.

## Evidence

- `git diff --check` passed.
- Nix evaluation returned version `latest-2026-07-12` and hash `sha256-OFLkVvKkVrai+Mv22Rhlmq2SVv+Gw6Py6sKhonCZsVk=`.
- GitHub's release asset digest and an independent URL prefetch matched the configured hash. The asset was produced by the successful release workflow for upstream merge commit `9560660a51ee0e0b0a538e36c0b2883b16281eff`.
- `nix build --no-link .#packages.x86_64-linux.auth-mini` passed and produced `/nix/store/y5ap29r9x0baqmcfj93rbblyx985mx2r-auth-mini-latest-2026-07-12`.
- `nix build --no-link .#nixosConfigurations.acorn.config.system.build.toplevel` passed and produced `/nix/store/b9a7f42kja84whcb7pwsgsz6xglndgci-nixos-system-acorn-25.11.20260630.b6018f8`.
- The evaluated Acorn `auth-mini.service` references the updated package, and that package is present in the built toplevel closure.

## Selection Rationale

The package build directly proves the fixed-output hash and binary packaging. The Acorn toplevel build proves host integration without performing another live switch. Broader unrelated host checks would not add useful evidence for this two-line package pin update.

## Residuals

- `auth-mini --help` exits with an unsupported-argument error because the application has no help flag. This is unrelated to startup and is non-blocking.
- The upstream URL intentionally remains mutable `latest`; the fixed-output hash fails closed if it moves again.
