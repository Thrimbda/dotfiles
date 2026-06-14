# Tasks: Dotfiles Flake Update Warning Cleanup

## Status

- Current stage: wiki writeback complete; task ready for user handoff.
- Execution mode: default implementation mode, low-to-medium risk compatibility path.
- Worktree: main checkout, retrospective Legion completion after user requested workflow.
- Branch: current checkout branch.

## Checklist

- [x] Update flake inputs with `nix flake update`.
- [x] Fix package removals and renamed package attributes.
- [x] Fix NixOS module option and deprecation warnings emitted by `axiom` build.
- [x] Refactor module platform gating enough to remove the `specialArgs.pkgs` build warning.
- [x] Preserve custom flake metadata outputs needed by `hey`.
- [x] Confirm `axiom` system build succeeds without warnings.
- [x] Record verification report.
- [x] Record readiness review.
- [x] Produce walkthrough.
- [x] Write Legion wiki update.

## Handoff Notes

- This task was initiated from a user request to update all packages and then explicitly brought under Legion workflow after implementation had already occurred.
- No system switch was run.
- Remaining `nix flake check --no-build` warnings are about custom flake outputs and intentionally retained workflow metadata, not the `axiom` build path.
