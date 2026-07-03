# Tasks

## Current Phase
- [x] Brainstorm and contract materialization
- [x] Worktree envelope setup
- [x] Implementation
- [x] Verification
- [x] Change review
- [x] Walkthrough and PR body
- [x] Wiki writeback

## Checklist
- [x] Confirm scope: repair `hey` activation staging environment, not native `c1ctl hook` migration.
- [x] Capture live failure evidence from `nixos-activation.service` logs.
- [x] Patch `modules/hey.nix` to set XDG fallbacks, staging cache dirs, and tool PATH.
- [x] Verify generated activation script contains the expected guards.
- [x] Verify Axiom toplevel build.
- [x] Confirm live `hey hook startup` and Caelestia process state after runtime repair.
- [x] Complete required Legion closeout artifacts before PR lifecycle.
- [ ] Complete PR lifecycle.
