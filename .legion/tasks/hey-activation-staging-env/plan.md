# Hey Activation Staging Environment

## Task ID
`hey-activation-staging-env`

## Goal
Make Axiom's `hey` user activation rebuild the JPM runtime reliably after the previous runtime has been damaged or invalidated.

## Problem
The current Axiom session failed to start Caelestia because `hey hook startup` could not load `spork/path`. PR #119 changed the rebuild to stage a new JPM tree before replacing the active one, but live activation logs show the staged rebuild still fails. JPM can reach GitHub, but the staging environment is incomplete: JPM's git cache parent is missing, `jpm run deploy` shells out to `jpm` through `PATH`, and `hey` module loading expects XDG directories including `XDG_RUNTIME_DIR`.

## Acceptance
- A staged `hey` JPM rebuild creates the directories JPM expects before dependency fetches begin.
- `jpm deps` and `jpm run deploy` can find `jpm`, `git`, `gcc`, and core utilities without relying on an incidental login-shell PATH.
- Activation supplies XDG fallback directories so loading `hey` does not fail with `Invalid XDG directory: runtime`.
- Existing behavior remains staged: a failed rebuild keeps a usable active runtime and fails only when no usable runtime remains.
- Axiom Nix evaluation/build and focused activation-script checks pass.

## Scope
- Update `modules/hey.nix` activation staging environment only.
- Repair the live session enough to validate `hey hook startup` and Caelestia startup behavior.
- Record verification and review evidence in this task.

## Non-goals
- Do not migrate `hey hook` to native `c1ctl hook` in this task.
- Do not Nix-build or vendor all Janet/JPM dependencies yet.
- Do not change Caelestia startup hooks, Hyprland configuration, or unrelated Axiom host settings.
- Do not touch user-local dirty/untracked main-worktree files.

## Assumptions
- The user activation service runs as the target user and normally has `/run/user/<uid>` available.
- `jpm deps` still uses git-backed dependency fetches; eliminating network dependency is a later hardening task.
- `heyWrapper` uses the repo source in the Nix store plus the user JPM dependency tree, so restoring `spork/path` and companion deps is sufficient for startup hooks.

## Constraints
- Keep the change minimal and declarative in the Nix module.
- Preserve the staging replacement semantics introduced by PR #119.
- Follow the worktree/PR delivery envelope.

## Risks
- Full resilience still depends on GitHub access during a first rebuild when no old runtime is usable.
- If user activation ever runs without a real user runtime directory, `XDG_RUNTIME_DIR` fallback may only satisfy module loading; runtime commands still need the real session environment.

## Design Summary
The recommended path is to make the existing staged rebuild self-contained enough to run from activation: set XDG defaults before probing or rebuilding, create `$JANET_TREE/lib/.cache` and staging bin directories before `jpm deps`, and prepend the exact tool paths needed by `project.janet` and JPM to `PATH`. This fixes the observed activation failures without changing the dependency model or the startup hook contract.

## Phases
1. Materialize this task contract.
2. Implement the minimal `modules/hey.nix` environment fix inside a worktree.
3. Run focused activation-script and Axiom build validation.
4. Run change review, walkthrough, wiki writeback, and PR lifecycle.
