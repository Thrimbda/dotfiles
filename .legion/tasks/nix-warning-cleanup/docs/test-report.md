# Test Report

## Summary

PASS for the scoped warning cleanup on representative NixOS evaluation and dry-run build.

## Commands

- `nix eval --impure --json .#hostMetadata`
- `nix eval --impure --raw .#nixosConfigurations.axiom.config.system.build.toplevel.drvPath`
- `nix build --impure --dry-run .#nixosConfigurations.axiom.config.system.build.toplevel`
- `grep` checks for exact deprecated local references: `pkgs.system`, `mesa.drivers`, `hardware.pulseaudio`, and `pkgs.stdenv.isDarwin` / `pkgs.stdenv.isLinux` in modules.

## Evidence

- `hostMetadata` evaluates successfully.
- `axiom` NixOS toplevel evaluates successfully: `/nix/store/1hf4qk5hraf1dsbqcmyzgzzx3r3yvsqa-nixos-system-axiom-25.11.20260203.e576e3c.drv`.
- `axiom` dry-run build succeeds far enough to produce the planned build/fetch set and emits none of the reported warnings.
- Exact-source searches for the reported deprecated local references return no matches.
- A temporary control check confirmed that re-adding `specialArgs.pkgs` still reproduces the original `specialArgs.pkgs` warning even with `readOnlyPkgs`, so removing that argument is required.

## Skipped Or Limited

- Privileged `nixos-rebuild switch` was not run; repository-level evaluation/dry-run build is the relevant non-privileged validation for this warning cleanup.
- Batch evaluation of all NixOS hosts was attempted but stopped on an unrelated existing package rename: `godot_4-export-templates` has been renamed to `godot_4-export-templates-bin`.
- `darwinConfigurations.charlie` toplevel evaluation on this Linux machine stopped because it tried to build/fetch `aarch64-darwin` derivations, which are not available for the current `x86_64-linux` system. `hostMetadata` still covers Darwin host discovery.

## Why These Checks

The reported warnings are evaluation-time warnings. Evaluating and dry-running a NixOS system that enables the affected desktop/audio/agenix paths directly exercises the warning sources without requiring a privileged switch or building the full system closure.
