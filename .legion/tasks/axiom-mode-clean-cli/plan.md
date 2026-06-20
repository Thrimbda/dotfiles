# Axiom Mode Clean CLI

## Goal

Replace the first-pass inline shell implementation of `axiom-mode` with a clean, standalone Rust CLI package that sits alongside other repository packages and remains independent of `hey`.

## Problem

The merged `axiom-cli-mode` task delivered the correct systemd behavior, but the command implementation is an ugly inline `writeShellScriptBin` block embedded in `hosts/axiom/default.nix`. That makes the host file harder to scan, hides command behavior inside a Nix string, and gives the CLI no clean source/package boundary.

## Acceptance

- `axiom-mode` is implemented as a Rust binary, not Python and not an inline Bash script.
- The CLI package lives as a repository package parallel to existing `packages/*` entries.
- `hosts/axiom/default.nix` references the package instead of embedding command logic.
- Existing user-facing behavior remains: `axiom-mode cli`, `axiom-mode desktop`, `axiom-mode status`, and aliases from the previous task.
- The command remains independent of `hey`.
- Validation proves package build, help output, and Axiom system relationships still evaluate.

## Scope

- Add `packages/axiom-mode` as a tiny Rust crate.
- Replace the host-local inline `writeShellScriptBin` with `pkgs.callPackage ../../packages/axiom-mode {}`.
- Update Legion task/wiki evidence for this follow-up.

## Non-Goals

- Do not change `axiom-cli.target` semantics.
- Do not add a reusable NixOS module for mode switching.
- Do not add external Rust dependencies or a broader CLI framework.
- Do not change remote access services or power-management policy.

## Risks

- Rust package wiring can accidentally drop the `systemctl` store path or command aliases if not validated.
- The package must stay Linux-only because it uses NixOS/systemd and `/run/wrappers/bin/sudo` semantics.

## Design Summary

Create a no-dependency Rust CLI with fixed target names and fixed `systemctl` argv calls. Nix injects the systemd store path at compile time through `AXIOM_MODE_SYSTEMCTL`. The host config installs the package and keeps the existing `axiom-cli.target` block unchanged.

## Phases

- Implement Rust package and host reference cleanup.
- Validate package build, help output, generated system package presence, target relationships, and toplevel dry-run.
- Review diff for scope and command safety.
- Update walkthrough/wiki and deliver through PR lifecycle.
