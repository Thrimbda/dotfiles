# Axiom Caelestia Keep Awake Path Fix - Log

## Session Progress (2026-05-15)

### Completed

- Investigated the live Axiom report that Keep Awake was not enabled after login.
- Confirmed `axiom-caelestia-keep-awake.service` was installed and enabled but failed at `2026-05-15 13:02:06 CST`.
- Root cause: the helper invoked `${caelestia-cli}/bin/caelestia shell idleInhibitor enable`; the Python CLI tries to execute `caelestia-shell` by name, but the generated oneshot unit has only a minimal NixOS `PATH`, causing `FileNotFoundError`.
- Enabled Keep Awake in the current live session with the evaluated `caelestia-shell` absolute path and display environment; IPC returned `true`.
- Opened worktree `.worktrees/axiom-caelestia-keep-awake-path-fix/` on branch `legion/axiom-caelestia-keep-awake-path-fix` from latest `origin/master`.
- Implemented the persistent fix by changing `axiom-caelestia-keep-awake` to call `${caelestia-shell}/bin/caelestia-shell ipc call idleInhibitor enable` directly.
- Verification passed: targeted Nix assertions confirmed direct shell IPC usage and old wrapper absence, `git diff --check` passed, and the Axiom toplevel build passed.
- Readiness review passed with no blocking findings.
- Walkthrough and wiki writeback completed.

### In Progress

- PR lifecycle: commit, push, open PR, attempt auto-merge, follow checks/review, cleanup, and refresh main workspace.

### Blockers

(None)

## Key Decisions

| Decision | Reason | Date |
|---|---|---|
| Call `caelestia-shell` by evaluated absolute path in the oneshot helper | Avoids the Caelestia CLI subprocess `PATH` dependency inside a minimal systemd user unit. | 2026-05-15 |
