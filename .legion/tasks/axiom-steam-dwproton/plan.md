# Axiom Steam DWProton

## Goal

Add an opt-in Steam compatibility-tool integration for DWProton and enable it on Axiom.

## Problem

Axiom needs access to a Proton compatibility tool with newer patches than the standard Valve/GE options exposed through nixpkgs. The current local worktree already sketches the desired shape: add the `imaviso/dwproton-flake` input, expose a Steam module option, and enable it only for Axiom.

## Acceptance

- The repository flake includes a pinned `dwproton` input following the intended nixpkgs baseline.
- `modules.desktop.apps.steam` exposes an opt-in `dwproton.enable` option defaulting to false.
- When enabled, Steam receives the DWProton package through `programs.steam.extraCompatPackages`.
- Axiom enables the option under its existing Steam app configuration.
- Hosts that only set `steam.enable = true` keep existing behavior.
- Verification proves Axiom evaluates/builds with the new package and a representative non-DWProton default path remains unaffected.

## Scope

- Update `flake.nix` / `flake.lock` for the new flake input.
- Update the shared Steam module with an opt-in compatibility package hook.
- Update Axiom host config to enable DWProton.
- Record validation evidence and Legion summary.

## Non-Goals

- Do not change Steam runtime, Gamescope, MangoHud, Proton-GE, or per-game launch options.
- Do not claim any specific game compatibility without live Steam testing.
- Do not enable DWProton globally for every Steam host.

## Assumptions

- `imaviso/dwproton-flake` exposes `packages.<system>.dw-proton` for Axiom's platform.
- `programs.steam.extraCompatPackages` is the correct existing NixOS surface for adding compatibility tools.
- A Nix build/eval is enough for repository readiness; live Steam selection remains a post-deploy smoke check.

## Constraints

- Preserve existing Steam module defaults for other hosts.
- Keep this as a small app module integration, not a broader Steam redesign.
- Commit/PR delivery should use the existing Legion worktree lifecycle.

## Risks

- Upstream DWProton package naming or outputs can change; validation must evaluate/build the exact package output.
- Live Steam may require a session restart or Steam restart before the compatibility tool appears.

## Recommended Direction

Use the existing local diff as the implementation direction: add `dwproton` as a flake input, expose `modules.desktop.apps.steam.dwproton.enable`, append the package to `extraCompatPackages` only when enabled, and turn it on in Axiom's Steam configuration.

## Phases

- Brainstorm: materialize this contract from the current local diff.
- Implementation: reproduce the scoped change in an isolated worktree.
- Verification: evaluate/build the DWProton package and affected NixOS/Home Manager surfaces.
- Review and delivery: review, walkthrough, wiki writeback, PR, checks, cleanup, main refresh.
