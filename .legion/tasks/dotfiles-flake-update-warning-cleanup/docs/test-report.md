# Test Report

## Summary

- Result: PASS
- Scope: flake input update plus compatibility and warning cleanup for the `axiom` NixOS system build.
- Primary claim: `axiom` builds successfully after the flake update and the `nix build` path is warning-free.

## Commands

### Axiom System Build

- Command: `nix build .#nixosConfigurations.axiom.config.system.build.toplevel --no-link`
- Result: PASS
- Evidence: final cached rerun produced no output.
- Why: this is the strongest direct validation for the user's explicit requirement to fix warnings emitted by the `nix build` path for the updated `axiom` system.

### Flake Evaluation

- Command: `nix flake check --no-build`
- Result: PASS with expected warnings for custom flake outputs.
- Evidence: all compatible NixOS configurations evaluated: `atlas`, `axiom`, `acorn`, `aliyun-acorn`, `azar`, `cone-wsl`, `harusame`, `ramen`, and `udon`.
- Expected warnings: `unknown flake output` for `hostData`, `hostMetadata`, `hostSystems`, and `_heyArgs`.
- Why warnings remain: `lib/hey/lib.janet` queries `.#hostMetadata.<host>`, so removing these outputs would break existing local workflow metadata access. These warnings are not emitted by the final `axiom` `nix build` validation path.
- Additional note: `nix flake check --no-build` reports omitted incompatible systems for Darwin and non-current Linux architectures; this is normal for a single-system check without `--all-systems`.

### Diff Whitespace Check

- Command: `git diff --check`
- Result: PASS
- Why: validates the pending code and Legion documentation diff for whitespace errors before handoff.

## Fixed Warning/Error Classes

- Removed package reference: `nixVersions.nix_2_19` -> `nixVersions.stable`.
- Insecure default package: explicit Docker daemon/user package switched to `docker_29`.
- Invalid path handling: module discovery helpers now compose paths with path addition rather than stringified store paths.
- Renamed package: `godot_4-export-templates` -> `godot_4-export-templates-bin`.
- Removed font package set: `pkgs.nerdfonts` -> `pkgs.nerd-fonts.symbols-only`.
- Deprecated packages: `mesa.drivers` -> `mesa`; `xorg.xrandr` -> `xrandr`.
- Renamed option: `hardware.pulseaudio` -> `services.pulseaudio`.
- Deprecated package system attr: `pkgs.system` -> `pkgs.stdenv.hostPlatform.system`.
- NixOS pkgs plumbing warning: removed NixOS `specialArgs.pkgs` and used `nixpkgs.pkgs` with nixpkgs `read-only.nix`.
- Download buffer warning: raised `nix.settings.download-buffer-size`.

## Skipped

- No `nixos-rebuild switch` was run; the user asked for package/flake update and build-warning cleanup, not activation.
- No PR lifecycle was run; the user did not request commit, push, or PR creation.
