# Implementation Plan: C1ctl Hey Rust Migration

## Milestone 1: Rename and package c1ctl

### Scope

- `packages/axiomctl/**` -> `packages/c1ctl/**`
- `hosts/axiom/default.nix`
- `hosts/axiom/README.org`

### Steps

- [x] Rename the Rust package directory to `packages/c1ctl`.
- [x] Rename Cargo package and lockfile package name to `c1ctl`.
- [x] Rename Nix package `pname` to `c1ctl`.
- [x] Rename compile-time env vars from `AXIOMCTL_*` to `C1CTL_*`.
- [x] Update Axiom host `callPackage` and installed package variable.
- [x] Update README references from `axiomctl` to `c1ctl`.

### Verification

- `nix build --impure --no-link --print-out-paths .#c1ctl`
- Axiom package-list eval shows `c1ctl`.

### Rollback Notes

- Revert package rename and host wiring; no data migration is involved.

## Milestone 2: Implement Rust foundation commands

### Scope

- `packages/c1ctl/src/main.rs`

### Steps

- [x] Keep current mode/status/reload behavior under `c1ctl` naming.
- [x] Add global parsing for `-!`, `-?`, `-??`, `-???`, `-h`, `--help`, `help`, and `which`.
- [x] Implement `path` with existing Janet path semantics.
- [x] Implement executable search path and resolver semantics.
- [x] Implement `which`, `help`, direct path dispatch, `.foo`, non-Rofi `@namespace`, `wm`, `host`, `theme`, and `exec`.
- [x] Delegate `@rofi` as a whole argv operation to existing Janet `hey` instead of resolving or executing Rofi scripts in Rust.
- [x] Set `DOTFILES_HOME`, computed `PATH`, `HEYSCRIPT`, `HEYDRYRUN`, and `HEYDEBUG` for Rust-executed dynamic scripts.
- [x] Delegate unported commands to existing Janet `hey` while preserving debug/dry-run environment.
- [x] Ensure all process execution uses argv arrays, not shell strings.

### Verification

- `rustfmt --check packages/c1ctl/src/main.rs`
- Built binary safe checks:
  - `c1ctl --help`
  - `c1ctl mode --help`
  - `c1ctl path home`
  - `c1ctl path xdg data`
  - `c1ctl which .backup`
  - `c1ctl which @rofi wifimenu` delegated to Janet compatibility
  - `c1ctl help path`
- Dynamic script env check for `DOTFILES_HOME`, `PATH`, `HEYSCRIPT`, `HEYDRYRUN`, and `HEYDEBUG`.
- Delegated command global-option check for dry-run/debug propagation.
- Delegation safe check for an unported command without executing destructive behavior.

### Rollback Notes

- Existing `hey` remains available; revert Rust changes if resolver or delegation parity fails.

## Milestone 3: Docs, validation, and delivery

### Scope

- Legion task docs.
- Legion wiki current truth.
- PR body and walkthrough.

### Steps

- [ ] Record validation evidence in `docs/test-report.md`.
- [ ] Run implementation review and record result.
- [ ] Produce walkthrough and PR body.
- [ ] Update wiki decisions/patterns/maintenance/task summary to supersede `axiomctl` boundary.
- [ ] Commit, rebase, push, open PR, and follow checks/review to terminal state.

### Verification

- `git diff --check`
- PR checks/review complete.

### Rollback Notes

- Revert docs with code rollback.
