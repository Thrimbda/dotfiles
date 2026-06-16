# Review Change

## Decision

PASS.

## Blocking Findings

None.

## Scope Review

- In scope: NixOS `pkgs` injection path, reported deprecated names, and platform guards required by the `readOnlyPkgs` migration.
- Out of scope avoided: no flake input bumps, no host policy changes, no unrelated deprecated package migrations.
- The wider platform-guard diff is justified by the removal of NixOS `specialArgs.pkgs`; `readOnlyPkgs` exposes module `pkgs` later, so import-time and top-level platform decisions must use `hostSystem` instead.

## Correctness Review

- NixOS now imports `nixpkgs.nixosModules.readOnlyPkgs`, sets `nixpkgs.pkgs = hostInfo.pkgs`, and no longer passes `pkgs` through NixOS `specialArgs`.
- Deprecated local references for the reported warnings were replaced or removed.
- NixOS overlay writes that were previously ignored are no longer written on NixOS under read-only pkgs. Darwin-only emacs overlay behavior is preserved behind the Darwin platform guard.
- Verification covers the representative `axiom` NixOS host that exercises Hyprland, audio, agenix, and desktop platform paths.

## Security Lens

Applied because the diff touches SSH and cloudflared modules. No auth, credential, firewall, tunnel routing, or service hardening behavior was changed; only platform predicates moved from `pkgs.stdenv` to `hostSystem`.

## Residual Risk

- Full all-host NixOS evaluation is still blocked by an unrelated existing `godot_4-export-templates` package rename.
- Darwin toplevel evaluation cannot complete on this Linux machine due unavailable `aarch64-darwin` build support, but the changed Darwin platform guards are string-equivalent to the previous `pkgs.stdenv.isDarwin` checks.
