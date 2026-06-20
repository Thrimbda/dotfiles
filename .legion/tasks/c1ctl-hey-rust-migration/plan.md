# C1ctl Hey Rust Migration

## Name

C1ctl Hey Rust Migration

## Task ID

`c1ctl-hey-rust-migration`

## Goal

Rename the merged `axiomctl` Rust CLI to `c1ctl` and start migrating `hey` from Janet into Rust, excluding Rofi-backed functionality. This task should deliver the first safe migration slice, not an all-at-once replacement of every Janet script.

## Problem

`axiomctl` is now too narrow a name for the intended direction. The desired CLI is a personal control surface for C1's dotfiles and hosts, not only an Axiom mode switcher. `hey` already owns the broad command surface, but it is implemented in Janet with dynamic dispatch and mixed dotfiles behaviors. A direct one-shot rewrite would risk breaking rebuild, profile, hook, path, and desktop workflows at the same time.

The current direction is therefore a staged Rust migration: introduce `c1ctl` as the canonical Rust CLI, move carefully selected non-Rofi `hey` behavior into it, and keep compatibility wrappers or fallbacks until later slices prove parity.

## Acceptance

- The Rust package and installed binary are renamed from `axiomctl` to `c1ctl`.
- Axiom host config installs `c1ctl`; current docs and Legion wiki use `c1ctl` as the current CLI name.
- Existing Axiom mode behavior remains available under `c1ctl mode cli`, `c1ctl mode desktop`, `c1ctl mode status`, and top-level `cli` / `desktop` / `status` aliases if retained.
- The first Rust migration slice includes a documented, validated subset of non-Rofi `hey` commands appropriate for immediate migration.
- Rofi-backed functionality is explicitly out of scope and remains outside `c1ctl`.
- Existing Janet `hey` remains available for commands not yet migrated; this PR must not strand workflows that still depend on it.
- Validation proves package build, CLI help, migrated command behavior, Axiom host eval, and compatibility boundaries.

## Assumptions

- `c1ctl` is the desired durable binary name.
- The first implementation slice should be mergeable and reversible; it should not delete the Janet `hey` implementation wholesale.
- Rofi commands include `config/rofi/**`, `lib/hey/rofi*.janet`, and any `@rofi` dynamic dispatch path.
- Non-Rofi `hey` features should be grouped by migration risk before implementation.

## Constraints

- Use Legion and PR-backed worktree delivery.
- Do not edit the dirty main workspace.
- Preserve current deployment safety for `hey sync` and other high-value workflows unless they are fully validated in Rust.
- Do not move user-controlled dynamic script execution into privileged Rust paths without explicit design review.
- Do not remove Janet libraries or wrappers until parity and rollback are proven.

## Risks

- `hey` is both a command runner and a scripting substrate. Replacing only the top-level CLI can break downstream zsh/Janet scripts if environment variables, paths, debug/dry-run, or help behavior diverge.
- Dynamic dispatch (`hey .foo`, `hey @namespace`, `hey wm`, `hey host`, `hey exec`) can easily become a shell-injection or PATH-trust problem if rewritten carelessly.
- Nix workflows (`sync`, `pull`, `profile`, `gc`, `build`) are high-impact and need stronger validation than simple help output.
- Current wiki truth says broad workflows remain in `hey`; this task intentionally supersedes that decision and must update wiki after implementation.

## Scope

- Rename `packages/axiomctl` to `packages/c1ctl` and update Axiom installation/docs.
- Design a migration matrix for non-Rofi `hey` commands.
- Implement the first low-risk Rust migration slice inside `c1ctl` after RFC approval.
- Keep compatibility for non-migrated `hey` behavior.
- Update Legion docs and wiki with the new migration boundary.

## Non-Goals

- Do not port Rofi menus or Rofi helper libraries.
- Do not delete the Janet `hey` implementation in this first slice.
- Do not attempt one-PR parity for every `hey.d` command unless the design review explicitly approves a narrower safe set.
- Do not replace Caelestia-owned desktop controls.
- Do not change systemd target semantics, Axiom remote access services, or broad host service policy.

## Design Summary

The recommended approach is staged migration. `c1ctl` becomes the canonical Rust package and CLI name. The first implementation should migrate commands that are either already part of `axiomctl` or have narrow, fixed behavior and good validation surfaces. Higher-risk commands remain delegated to `hey` or are deferred to later tasks with explicit parity tests.

Because this changes the CLI ownership boundary and touches dynamic dispatch, the next phase must produce an RFC before implementation. The RFC should classify commands into immediate migration, compatibility delegation, and future migration buckets.

## Phases

- Materialize this contract in a fresh worktree from `origin/master`.
- Write RFC covering command matrix, compatibility strategy, safety model, and first-slice acceptance.
- Review RFC before coding.
- Implement the approved first slice in Rust.
- Validate Rust build/help, migrated behavior, host eval, compatibility fallback, and stale-name references.
- Review implementation, produce walkthrough, write wiki updates, and complete PR lifecycle.
