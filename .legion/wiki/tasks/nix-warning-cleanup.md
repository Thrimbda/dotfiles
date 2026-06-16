# Nix Warning Cleanup

## Status

Implementation reviewed and ready for PR delivery.

## Summary

NixOS system construction now follows the recommended read-only package-set path: import `nixpkgs.nixosModules.readOnlyPkgs`, set `nixpkgs.pkgs = hostInfo.pkgs`, and do not pass `pkgs` through NixOS `specialArgs`.

Because `readOnlyPkgs` means module `pkgs` is provided through configuration, modules that need platform decisions while imports or top-level config shape are collected now use a plain `hostSystem` special argument instead of forcing `pkgs.stdenv.isLinux` or `pkgs.stdenv.isDarwin` early.

The reported deprecated references were also updated: `mesa.drivers` became `mesa`, `pkgs.system` became `pkgs.stdenv.hostPlatform.system`, and `hardware.pulseaudio` became `services.pulseaudio`.

## Evidence

- `nix eval --impure --json .#hostMetadata` passed.
- `nix eval --impure --raw .#nixosConfigurations.axiom.config.system.build.toplevel.drvPath` passed with no reported warning strings.
- `nix build --impure --dry-run .#nixosConfigurations.axiom.config.system.build.toplevel` passed with no reported warning strings.
- Exact-source searches for `pkgs.system`, `mesa.drivers`, `hardware.pulseaudio`, and module-level `pkgs.stdenv.isDarwin` / `pkgs.stdenv.isLinux` returned no matches.
- A control evaluation confirmed that keeping NixOS `specialArgs.pkgs` still reproduces the original warning even after importing `readOnlyPkgs`.
- `docs/review-change.md` recorded PASS; security lens found no auth, credential, firewall, or tunnel behavior changes.

## Current Decisions

- NixOS hosts should reuse the preconfigured host package set through `readOnlyPkgs` + `nixpkgs.pkgs`, not through `specialArgs.pkgs`.
- Import-time platform decisions should use `hostSystem`; do not force module `pkgs` while imports or top-level optional config shape are being collected under read-only pkgs.
- NixOS modules should not write `nixpkgs.overlays` or `nixpkgs.config` when a prebuilt pkgs set is supplied; move real package-set customization into the flake package construction path instead.

## Follow-Up

- Full all-host NixOS evaluation is blocked by an unrelated existing `godot_4-export-templates` package rename. Fix that in a separate scoped task if full-host evaluation becomes a gate.
- Darwin toplevel evaluation still needs a Darwin-capable machine or builder; Linux can validate host discovery but not all Darwin build-time effects.
