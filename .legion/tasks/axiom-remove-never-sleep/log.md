# Axiom Remove Never Sleep - Log

## Session Progress (2026-05-27)

### Completed
- Entered Legion workflow from a user request to remove the obsolete `axiom-caelestia-never-sleep` definition, implementation, and usage.
- Observed main workspace user changes in `config/hypr/hypridle.conf`: lock timeout changed to 900 seconds and DPMS timeout changed to 1800 seconds.
- Opened worktree `.worktrees/axiom-remove-never-sleep/` on branch `legion/axiom-remove-never-sleep-remove-inhibitor` from `origin/master`.
- Materialized the task contract in `plan.md` and `tasks.md`.
- Replayed the user's Hypridle timeout change in the worktree and corrected the DPMS comment to 30 minutes.
- Removed the generated `axiom-caelestia-never-sleep` script and `axiom-caelestia-never-sleep.service` declaration from `hosts/axiom/default.nix`.
- Updated Axiom README and wiki current-truth entries so the active policy is Caelestia `idleInhibitor` plus Hypridle lock/DPMS, without a repository-owned sleep inhibitor.
- Marked the previous never-sleep wiki task summary as superseded by this task.
- `git diff --check` passed as an engineer-stage local check.
- Verification passed: active-reference search found no current references, Hypridle timeout grep confirmed 900/1800 seconds with matching comments, `git diff --check` passed, targeted Nix eval returned all true, and the Axiom toplevel build succeeded.
- Wrote verification evidence to `docs/test-report.md`.
- Review passed with no blocking findings; security lens found no blocker because the change removes a sleep blocker without broadening polkit/logind permissions.
- Wrote reviewer-facing walkthrough and PR body evidence.

### In Progress
- PR lifecycle.

### Blocked / Pending
- No blocker currently known.

---

## Key Files
**`config/hypr/hypridle.conf`** [planned]
- Role: Axiom Hypridle lock and DPMS idle policy.

**`hosts/axiom/default.nix`** [planned]
- Role: Axiom host-local Caelestia/session wiring and user services.

**`hosts/axiom/README.org`** [planned]
- Role: Human-facing Axiom host behavior documentation.

**`.legion/wiki/**`** [planned]
- Role: Cross-task current truth for Axiom power policy.

---
*Updated: 2026-05-27 00:00*
