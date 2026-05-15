# Axiom Caelestia Keep Awake Default - Log

## Session Progress (2026-05-14)

### Completed

- Entered Legion workflow for a modification request and created new task `axiom-caelestia-keep-awake-default` because no explicit task directory was provided.
- Opened isolated worktree `.worktrees/axiom-caelestia-keep-awake-default/` on branch `legion/axiom-caelestia-keep-awake-default-reuse` from `origin/master`.
- Materialized the stable contract and design-lite: replace custom Axiom no-sleep mode with Caelestia `idleInhibitor` default enablement.
- Implemented the replacement in `hosts/axiom/default.nix`: removed `axiom-sleep-mode`, removed Power Mode launcher entries, removed the direct Hypridle override, removed custom sleep-inhibitor services, and added `axiom-caelestia-keep-awake.service` to enable Caelestia `idleInhibitor` on session start.
- Added `hosts/axiom/README.org` documenting Caelestia-backed Keep Awake shell entrypoints and the graphical-session boundary.
- Engineer smoke eval passed for service wiring and absence of old wrapper/service/package/direct Hypridle override.
- Verification completed with PASS in `docs/test-report.md`: targeted Nix assertions, host-level old-wrapper grep, `git diff --check`, and Axiom toplevel build all passed.
- Readiness review completed with PASS in `docs/review-change.md`; security lens found no blocking issue and noted that the new behavior is session-scoped rather than system-wide.
- Generated reviewer-facing walkthrough and PR body in `docs/report-walkthrough.md` and `docs/pr-body.md`.
- Completed Legion wiki writeback: added `wiki/tasks/axiom-caelestia-keep-awake-default.md`, marked `axiom-no-sleep-power-mode` historical/superseded, and updated decisions, patterns, maintenance, index, and wiki log.
- Rebased onto latest `origin/master` and resolved conflicts by preserving upstream Axiom opencode/audio/Fcitx/Cloudflare Access changes plus this task's Caelestia Keep Awake replacement.
- Post-rebase validation passed: targeted Nix assertions including `opencodePathPreserved=true` and `fcitxThemeKept=true`, `git diff --check`, and Axiom toplevel build.

### In Progress

- PR lifecycle: commit, push branch, create PR, attempt auto-merge, follow checks/review, then cleanup and refresh main workspace when possible.

### Blockers

(None)

## Key Decisions

| Decision | Reason | Alternative | Date |
|---|---|---|---|
| Supersede `axiom-sleep-mode` with Caelestia `idleInhibitor` | Caelestia already has the Keep Awake UI and IPC, so a second Axiom mode state is duplicative. | Keep wrapper and document it separately. | 2026-05-14 |
| Treat Keep Awake as graphical-session policy | Caelestia's inhibitor depends on the shell session and aligns with the visible UI. | System-wide/headless sleep inhibitor. | 2026-05-14 |
