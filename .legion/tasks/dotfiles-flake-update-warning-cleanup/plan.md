# Dotfiles Flake Update Warning Cleanup

## Goal

Update all flake inputs and make the current `axiom` NixOS build evaluate and build cleanly after the update, with package and module compatibility fixes committed to the dotfiles tree.

## Problem

Running `nix flake update` moved the repository to newer nixpkgs and related inputs. The new inputs exposed removed packages, renamed options, deprecated package attributes, an insecure Docker default, and stricter flake/module validation. The user also explicitly required that warnings emitted by the `nix build` path be fixed rather than ignored.

## Acceptance

- `flake.lock` is updated by `nix flake update`.
- `nix build .#nixosConfigurations.axiom.config.system.build.toplevel --no-link` succeeds.
- The same `axiom` build is confirmed warning-free by a cached rerun with no output.
- Package removals and option renames introduced by the flake update are handled without adding insecure-package allowlists.
- `nix flake check --no-build` evaluates repository outputs and all NixOS host configurations that are compatible with the current system.
- Any remaining non-build warnings are documented if they are intentionally retained for existing workflow compatibility.
- Existing application behavior is preserved except where package names or platform-gating internals must change for compatibility.

## Scope

- Update `flake.lock` and compatibility shims needed by the new lock file.
- Fix `axiom` build warnings and errors caused by updated nixpkgs semantics.
- Keep changes focused on package renames, platform-gating refactors, NixOS module evaluation hygiene, and validation metadata.
- Record verification, readiness review, and walkthrough evidence under this Legion task.

## Non-goals

- Do not switch or activate the new system generation.
- Do not commit, push, or open a PR unless separately requested.
- Do not remove custom flake outputs such as `hostMetadata`, because existing `hey` tooling queries them.
- Do not redesign the repository's flake architecture beyond the minimum needed to silence the requested build warnings.
- Do not migrate unrelated deprecation warnings that are not emitted by the final `axiom` build path.

## Assumptions

- `axiom` is the active host the user cares about for the package update.
- A clean `nix build` warning surface is stricter than a clean `nix flake check`, because custom flake outputs are intentionally exposed for local tooling.
- The repository can continue exposing Legion task metadata and `hostMetadata` even though `nix flake check` warns about unknown custom outputs.
- Replacing insecure `docker_28` with `docker_29` is preferable to adding an insecure-package exception.

## Constraints

- The work was started before the user's explicit Legion workflow instruction, so the Legion task is a retrospective workflow completion rather than a pre-implementation worktree/PR envelope.
- Preserve already-completed main-worktree changes and do not revert unrelated user work.
- Use minimal compatibility edits; avoid broad refactors unless required to remove a build warning.

## Risks

- Moving platform decisions from `pkgs.stdenv` to explicit `isLinux` / `isDarwin` module arguments touches many modules and could affect Darwin evaluation if those args are not supplied consistently.
- Moving the Emacs overlay from a module-level `nixpkgs.overlays` option into host `pkgs` construction changes where the overlay is applied, though only hosts with `modules.editors.emacs.enable` should receive it.
- Updating all inputs can change runtime behavior of desktop packages even when evaluation and build succeed.

## Design Summary

Use the updated lock file as the new baseline, then repair compatibility at the narrowest failing points. Removed or renamed package attributes are replaced with their current equivalents. NixOS module warnings are addressed by using current option names and package attributes. The `specialArgs.pkgs` warning is resolved by making NixOS hosts import nixpkgs via `nixpkgs.pkgs` plus nixpkgs' `read-only.nix`, then removing module-level writes to `nixpkgs.overlays`. Platform checks that previously forced `pkgs` too early are changed to explicit `isLinux` / `isDarwin` module arguments. The final success criterion is the actual `axiom` system build being warning-free, not merely evaluable.

## Phases

1. Materialize retrospective Legion contract and implementation boundary.
2. Verify the updated flake and `axiom` build evidence.
3. Review change readiness and residual risks.
4. Produce walkthrough evidence.
5. Write Legion wiki summary and close task state.
