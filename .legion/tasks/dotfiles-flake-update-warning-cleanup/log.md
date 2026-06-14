# Dotfiles Flake Update Warning Cleanup Log

## 2026-06-14

- User requested updating all packages by updating the flake.
- Initial work was performed before the explicit Legion workflow instruction: checked worktree cleanliness, ran `nix flake update`, and began compatibility repair in the main checkout.
- `nix flake check --no-build` first exposed app metadata/path issues, removed `nix_2_19`, insecure default `docker_28`, invalid stringified module paths, renamed Godot export templates, and removed `pkgs.nerdfonts`.
- `axiom` build then exposed warnings for `specialArgs.pkgs`, `xorg.xrandr`, `mesa.drivers`, `hardware.pulseaudio`, `pkgs.system`, and Nix download buffering.
- Engineer stage: converted `mkApp` program paths to strings and added app metadata.
- Engineer stage: moved module path construction from string interpolation to path-aware `dir + "/name"` operations.
- Engineer stage: changed dev shell Nix from `nixVersions.nix_2_19` to `nixVersions.stable`.
- Engineer stage: changed Docker from insecure default `docker` / Docker 28 to `docker_29` for user package and daemon package.
- Engineer stage: updated Godot export templates to `godot_4-export-templates-bin` and Emacs symbol font to `nerd-fonts.symbols-only`.
- Engineer stage: replaced deprecated `hardware.pulseaudio` settings with `services.pulseaudio` settings.
- Engineer stage: replaced deprecated Hyprland-related `mesa.drivers` and `xorg.xrandr` references with `mesa` and `xrandr`.
- Engineer stage: added explicit `isLinux` / `isDarwin` module arguments and removed `specialArgs.pkgs` for NixOS by using `nixpkgs.pkgs` with nixpkgs `read-only.nix`.
- Engineer stage: moved the Emacs overlay out of module-level `nixpkgs.overlays` and into host package construction for hosts with Emacs enabled.
- Engineer stage: raised `nix.settings.download-buffer-size` to avoid the observed Nix download buffer warning on large updates.
- User then explicitly requested using Legion workflow to complete the task; this task was created retrospectively to record contract, verification, review, walkthrough, and wiki evidence.
- Verify stage: `nix build .#nixosConfigurations.axiom.config.system.build.toplevel --no-link` passed and final cached rerun produced no output, confirming the requested build-warning cleanup.
- Verify stage: `nix flake check --no-build` passed for compatible outputs and all NixOS host configurations; only expected custom-output warnings remain for metadata outputs used by `hey`.
- Verify stage: `git diff --check` passed.
- Review stage: `review-change` subagent returned PASS with no blocking findings; security lens was applied because privileged/auth-adjacent modules changed, with no blocking security issue found.
- Report stage: wrote implementation-mode `docs/report-walkthrough.md` and `docs/pr-body.md` from verification and review evidence.
- Wiki stage: added task summary plus flake update warning cleanup pattern and follow-up items for runtime smoke, custom-output warning policy, and Darwin/non-current architecture validation.
