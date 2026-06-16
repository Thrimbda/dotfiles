# Nix Warning Cleanup

## Contract

- Name: Nix Warning Cleanup
- Task ID: nix-warning-cleanup

## Goal

Remove the Nix evaluation warnings reported during `nix build` / `nixos-rebuild switch` without changing host behavior or broad flake architecture.

## Problem

Current evaluation emits warnings for outdated or discouraged NixOS/nixpkgs interfaces: passing `pkgs` through `specialArgs`, deprecated Mesa package aliases, deprecated `pkgs.system`, and the renamed PulseAudio option. These warnings add noise to rebuild output and can hide real evaluation issues.

## Acceptance

- The warning about `specialArgs.pkgs` no longer appears for NixOS evaluation.
- The `mesa.drivers` deprecation warnings are removed.
- The `system` rename warning is removed by using `stdenv.hostPlatform.system` where appropriate.
- The `hardware.pulseaudio` rename warning is removed by using `services.pulseaudio`.
- At least one representative NixOS configuration evaluates or builds far enough to confirm the warning cleanup, or any remaining blocker is documented with evidence.
- No unrelated host behavior is intentionally changed.

## Scope

- Update the flake/system construction path that currently injects `pkgs` through `specialArgs` for NixOS.
- Update local modules that reference deprecated nixpkgs/NixOS names involved in the reported warnings.
- Add Legion verification/review/walkthrough/wiki evidence for this task.

## Non-goals

- Do not redesign the custom `mkFlake` library.
- Do not change pinned nixpkgs channels or flake inputs.
- Do not migrate unrelated deprecated options not observed in this warning set.
- Do not run an actual privileged `nixos-rebuild switch` unless necessary; evaluation/build validation is sufficient.

## Assumptions

- NixOS modules can rely on the standard module argument `pkgs` once `nixpkgs.pkgs` is set, so `specialArgs.pkgs` is not required for NixOS modules.
- Host configuration functions outside the module system may still need an explicitly imported `pkgs` during host data construction.
- The reported warnings come from the current repository configuration rather than external user overlays.

## Constraints

- Use Legion workflow for task tracking and closeout.
- Keep the fix minimal and local to the warning sources.
- Preserve existing user or concurrent work in the checkout.

## Risks

- Removing `specialArgs.pkgs` from NixOS could expose a module that incorrectly expected the custom argument rather than the standard module `pkgs` argument.
- Adding `readOnlyPkgs` may make any in-module `nixpkgs.overlays`/`nixpkgs.config` assignments fail instead of being silently ignored; if such assignments are active for evaluated hosts, they must be addressed explicitly.
- Full `nixos-rebuild switch` may require privileges or machine-specific runtime state not available in this workspace.

## Design Summary

Use the upstream-recommended read-only pkgs path for NixOS by setting `nixpkgs.pkgs = hostInfo.pkgs`, importing the nixpkgs `readOnlyPkgs` module, and no longer passing `pkgs` in NixOS `specialArgs`. Then replace the reported deprecated names with their current equivalents in local modules. Validate by evaluating/building a representative host configuration and checking for the reported warning strings.

## Phases

1. Locate warning sources and create a stable Legion task contract.
2. Implement minimal Nix configuration updates.
3. Verify representative NixOS evaluation/build output no longer contains the reported warnings.
4. Review the change for scope and safety.
5. Produce walkthrough and wiki writeback evidence.
