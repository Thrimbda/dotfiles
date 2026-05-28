# Axiom Caelestia Idle Timeouts - Log

## Session Progress (2026-05-28)

### Completed
- Entered Legion workflow from the user request to determine which idle lock path is active and to align Caelestia's own idle timers with Axiom's Hypridle policy.
- Runtime/config investigation found that active Hypridle registers 900 second lock and 1800 second DPMS rules, while Caelestia upstream defaults still provide 180 second lock, 300 second DPMS, and 600 second `systemctl suspend-then-hibernate` actions when `general.idle.timeouts` is not overridden.
- Created worktree `.worktrees/axiom-caelestia-idle-timeouts/` on branch `legion/axiom-caelestia-idle-timeouts-align-idle` from `origin/master`.
- Materialized the task contract in `plan.md` and `tasks.md`.
- Added Axiom-owned Caelestia `general.idle` settings with 900 second lock and 1800 second DPMS entries and no 600 second sleep action.
- Extended the existing Caelestia shell pre-start migration so persisted mutable `shell.json` receives the same `general.idle` policy while preserving unrelated user settings.
- Updated Axiom README and wiki current-truth entries for the aligned Caelestia/Hypridle idle policy.
- Verification passed: `git diff --check`, targeted Nix assertions, focused automatic-sleep searches, jq migration syntax, and the Axiom toplevel build all passed.
- Review passed with no blocking findings; security lens found no blocker because the change removes an automatic sleep path and does not broaden permissions.
- Wrote reviewer-facing walkthrough and PR body evidence.
- Wrote wiki summary and current-truth writeback for `axiom-caelestia-idle-timeouts`.

### In Progress
- PR lifecycle.

### Blocked / Pending
- No blocker currently known.

---

## Key Files
**`hosts/axiom/default.nix`** [planned]
- Role: Axiom host-local Caelestia settings, shell config migration, and Keep Awake startup wiring.

**`config/hypr/hypridle.conf`** [validation]
- Role: Existing 900 second lock and 1800 second DPMS policy that Caelestia should match.

**`hosts/axiom/README.org`** [planned]
- Role: Human-facing Axiom host behavior documentation.

**`.legion/wiki/**`** [planned]
- Role: Cross-task current truth for Axiom idle policy.

---
*Updated: 2026-05-28 00:00*
