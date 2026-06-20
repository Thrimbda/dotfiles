# Report Walkthrough

## Profile

implementation

## Reviewer Summary

- `axiom-mode` has been moved out of `hosts/axiom/default.nix` into `packages/axiom-mode`, a no-dependency Rust crate.
- The user-facing command behavior and `axiom-cli.target` semantics remain unchanged.
- Validation and review both passed.

## Scope

In scope:

- Add Rust package `packages/axiom-mode`.
- Replace inline host shell with `pkgs.callPackage ../../packages/axiom-mode {}`.
- Record Legion verification/review/wiki evidence.

Out of scope:

- Change target semantics.
- Add a reusable module.
- Change remote access or power-management services.

## Evidence Map

| Claim | Evidence | Status |
|---|---|---|
| CLI is now Rust package | `docs/test-report.md` | PASS |
| Inline Bash implementation removed | `docs/test-report.md` | PASS |
| Axiom still installs `axiom-mode` | `docs/test-report.md` | PASS |
| Target/service relationships unchanged | `docs/test-report.md` | PASS |
| Security-sensitive sudo/systemctl path reviewed | `docs/review-change.md` | PASS |

## What Changed

The host now references a real package:

```nix
axiomMode = pkgs.callPackage ../../packages/axiom-mode {};
```

The CLI logic lives in `packages/axiom-mode/src/main.rs`. It parses a small enum of modes and calls `systemctl` with fixed target names.

## Verification / Review Status

- Verification: PASS.
- Review: PASS.
- Runtime isolate remains a live-host deployment smoke check.

## Risks and Limits

- The binary is Linux/NixOS-specific by design.
- `systemctl isolate` still immediately ends the graphical session for CLI mode, unchanged from the previous PR.

## Reviewer Checklist

- [ ] The host file is now readable and no longer contains inline CLI logic.
- [ ] Rust CLI behavior matches the previous command surface.
- [ ] No target/service semantics changed.

## Next Stage

Create PR, handle checks/review/merge, then clean up worktree and refresh the main workspace when safe.
