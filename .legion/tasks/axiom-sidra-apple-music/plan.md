# Axiom Sidra Apple Music

## Goal
Install Sidra declaratively for the `axiom` NixOS workstation so Apple Music is available as a desktop app with Linux media integration.

## Task ID
`axiom-sidra-apple-music`

## Problem
Apple Music has no official native Linux desktop client. The official web player works, but it has weak desktop integration. Sidra is a focused Apple Music desktop client with Nix flake support, so this dotfiles repo should make it available through the same declarative path used for other desktop apps.

## Acceptance
- The root flake tracks Sidra as an input in a narrow, explicit way.
- A desktop app module exposes `modules.desktop.apps.sidra.enable` and installs the Sidra package for Linux desktop users.
- The `axiom` host enables the Sidra module.
- Evaluation or build of the affected `axiom` NixOS configuration succeeds, or any blocker is documented with evidence.
- Work follows the Legion workflow with task-local implementation, verification, review, walkthrough, and wiki evidence.

## Assumptions
- The target host is `axiom`, the active x86_64 Linux workstation in this repo.
- Sidra's flake exposes `packages.${system}.default` as documented by the upstream README.
- Sidra can be installed as a user package; no system service or persistent data migration is needed.
- The existing desktop app module pattern is the right integration point.

## Constraints
- Keep the change minimal and aligned with existing `modules/desktop/apps/*.nix` style.
- Do not replace browser, audio, DRM, or Apple Music account configuration in this task.
- Preserve unrelated worktree changes.
- Use an isolated worktree/PR envelope for repository modifications after contract materialization.

## Risks
- Sidra is an external flake input, so the lockfile will change and builds depend on its upstream dependency graph.
- If Sidra's package output name changes, evaluation will fail and the module will need a small adjustment.
- Apple Music playback can still depend on upstream DRM/session behavior; this task only installs the client declaratively.

## Scope
- Update root flake inputs and lockfile as needed.
- Add a small `modules.desktop.apps.sidra` NixOS module.
- Enable the module for `hosts/axiom`.
- Record verification and closing evidence under this Legion task.

## Non-goals
- Do not install QQ Music, NetEase Cloud Music, Cider, or browser-specific Widevine settings in this task.
- Do not introduce a general music-player abstraction unless it becomes necessary.
- Do not change unrelated desktop launcher favorites, media defaults, audio stack, or browser configuration.

## Design Summary
Follow the existing app-module pattern: add Sidra as a root flake input, pass flake inputs through the module argument set already used by the repo, expose a `sidra.enable` option under `modules.desktop.apps`, and install the Sidra package for the host platform into `user.packages` when enabled. Enable only on `axiom` so the change is host-scoped and reversible.

## Phases
1. Materialize the Legion task contract.
2. Enter the worktree/PR envelope and implement the flake/module/host changes.
3. Verify the affected `axiom` NixOS configuration.
4. Review the implementation for scope and safety.
5. Produce walkthrough/wiki evidence and complete lifecycle cleanup.
