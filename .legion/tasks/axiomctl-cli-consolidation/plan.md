# Axiomctl CLI Consolidation

## Name

Axiomctl CLI Consolidation

## Task ID

`axiomctl-cli-consolidation`

## Goal

Rename the Axiom host-local Rust CLI from `axiom-mode` to a more durable `axiomctl` command, then consolidate only the Axiom-specific control capabilities that are appropriate to maintain as a typed Rust CLI.

## Problem

`origin/master` already moved the original inline shell `axiom-mode` into `packages/axiom-mode`, but the binary name still describes only one feature. Axiom now has a broader set of host-local control surfaces: switching between desktop and SSH-friendly CLI mode, checking the machine/session status, and triggering the reviewed Hyprland reload path. Keeping those behind a single-purpose `axiom-mode` name makes the next maintainable CLI boundary unclear.

At the same time, `hey` still owns broad dotfiles/Nix workflows and dynamic script dispatch. Rewriting all useful `hey` commands in Rust would expand scope, duplicate mature behavior, and risk changing deployment semantics. The right consolidation is narrower: Axiom host control commands with fixed verbs and fixed argv belong in `axiomctl`; broad dotfiles plumbing remains in `hey`.

## Acceptance

- The installed Axiom CLI binary is named `axiomctl`, not `axiom-mode`.
- The Rust package path and flake package export use `packages/axiomctl` / `.#axiomctl` naming.
- Axiom host configuration installs `axiomctl` and no longer references `packages/axiom-mode`.
- Existing mode switching remains available as `axiomctl mode cli`, `axiomctl mode desktop`, and `axiomctl mode status` with the same fixed `systemctl` target behavior as `axiom-mode`.
- Top-level convenience aliases remain for the old user workflow where useful: `axiomctl cli`, `axiomctl desktop`, and `axiomctl status`.
- `axiomctl reload` triggers the existing reviewed Hyprland reload path without introducing Rofi or user-controlled shell evaluation.
- Documentation and Legion wiki references are updated from `axiom-mode` to `axiomctl` where they describe current truth.
- Validation proves the Rust package builds, help output is coherent, Axiom installs the renamed package, target relationships remain intact, and stale `axiom-mode` package references are gone.

## Assumptions

- The user's phrase "our Rust CLI" refers to the existing `packages/axiom-mode` crate on `origin/master`.
- `axiomctl` is the preferred durable name because it reads as a host-local control CLI rather than a single feature.
- Backward-compatible `axiom-mode` installation is not required unless a future deployment task asks for a transition wrapper.
- Only commands with fixed behavior and Axiom-local ownership should move into Rust now.

## Constraints

- Do not rewrite the broad `hey` CLI or its Nix/dotfiles workflows.
- Do not add Rofi-backed commands to the Rust CLI.
- Do not add external Rust dependencies unless they materially reduce risk; a small no-dependency parser is acceptable.
- Keep privileged operations restricted to fixed target names and fixed `systemctl` argv.
- Keep Linux/systemd assumptions explicit in the package metadata.

## Risks

- Renaming the binary can break external scripts or muscle memory if documentation is not updated.
- Adding too many commands can turn `axiomctl` into a second `hey` rather than a narrow host-control CLI.
- Reload behavior must preserve the existing `hey reload` hook semantics or clearly remain a thin compatibility trigger.
- Nix package rename can leave stale references in host config, README, Legion wiki, or validation queries.

## Scope

- Rename `packages/axiom-mode` to `packages/axiomctl`.
- Rename Cargo package, Nix derivation, compile-time environment variable, error prefix, and usage text.
- Update `hosts/axiom/default.nix` to install the renamed package.
- Update `hosts/axiom/README.org` and relevant Legion wiki current-truth entries.
- Add a bounded `reload` verb that invokes the existing `hey reload` path through an injected store path.
- Keep mode switching and status behavior equivalent to the current Rust implementation.

## Non-Goals

- Do not port `hey sync`, `hey pull`, `hey gc`, `hey profile`, or dynamic script dispatch into Rust.
- Do not port Rofi menus or old `@rofi` commands.
- Do not replace Caelestia-owned screenshot, launcher, picker, emoji, brightness, media, or session controls.
- Do not change `axiom-cli.target` semantics or remote access service policies.
- Do not add a general plugin framework or user-script execution surface.

## Design Summary

Use `axiomctl` as the durable host-control command. Keep mode switching under a `mode` namespace while preserving top-level aliases for the common verbs. Add only one extra maintainable Axiom command now: `reload`, which delegates to the existing reviewed `hey reload` hook path via a Nix-injected `hey` store path. This keeps typed Rust ownership around fixed host-control verbs while leaving broad Nix/dotfiles operations in `hey`.

The Rust parser can stay no-dependency because the command surface is intentionally small. If the command surface grows after this task, a future task can revisit `clap` or another parser with a concrete need.

## Phases

- Create task docs and isolated worktree from latest `origin/master`.
- Rename the Rust package and update host/README/wiki references.
- Implement `axiomctl` command parsing for `mode`, aliases, `status`, and `reload`.
- Validate package build, help output, Axiom package wiring, target relationships, stale-reference greps, and formatting.
- Review final diff for scope, command safety, and rollback behavior.
- Produce walkthrough, wiki writeback, commit, rebase, push, and PR.
