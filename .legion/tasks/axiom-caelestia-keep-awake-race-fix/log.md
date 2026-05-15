# Axiom Caelestia Keep Awake Race Fix - Log

## Session Progress (2026-05-15)

### Completed

- Investigated the report that Keep Awake still was not enabled by default after the path fix.
- Confirmed the current generation no longer has `axiom-caelestia-keep-awake.service` or `caelestia-shell.service`; Caelestia is currently launched by `caelestia-session run` under the Hyprland session.
- Confirmed evaluated hooks run `06-caelestia-shell` before `07-caelestia-keep-awake`.
- Confirmed the deployed helper works when run manually in the current graphical session.
- Root cause: `caelestia-session start` backgrounds the shell runner and returns before IPC registration; the observed Caelestia instance registered about 11 seconds after session startup, while the helper retried for only about 10 seconds and was hidden by `|| true`.
- Opened worktree `.worktrees/axiom-caelestia-keep-awake-race-fix/` on branch `legion/axiom-caelestia-keep-awake-race-fix` from latest `origin/master`.
- Extended the helper retry loop from 20 attempts to 120 attempts, increasing the wait window from about 10 seconds to about 60 seconds.
- Verification passed: targeted Nix assertions confirmed hook ordering, direct IPC usage, 120 retry attempts, and old wrapper absence; `git diff --check` passed; Axiom toplevel build passed.
- Readiness review passed with no blocking findings.
- Walkthrough and wiki writeback completed.

### In Progress

- PR lifecycle: commit, push, open PR, attempt auto-merge, follow checks/review, cleanup, and refresh main workspace.

### Blockers

(None)

## Key Decisions

| Decision | Reason | Date |
|---|---|---|
| Extend the Keep Awake helper retry window instead of restoring a user service | Current Caelestia ownership is session-runner based; the remaining defect is a cold-start IPC registration race. | 2026-05-15 |
