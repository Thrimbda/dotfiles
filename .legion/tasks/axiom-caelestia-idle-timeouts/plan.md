# Axiom Caelestia Idle Timeouts

## Name
Axiom Caelestia Idle Timeouts

## Task ID
`axiom-caelestia-idle-timeouts`

## Goal
Align Caelestia's own idle timers with Axiom's Hypridle policy so both desktop idle paths lock after 15 minutes, turn DPMS off after 30 minutes, and never trigger automatic idle sleep.

## Problem
Axiom's checked-in Hypridle policy is already 900 seconds for lock and 1800 seconds for DPMS. Runtime investigation showed Caelestia shell also starts its own `IdleMonitors` from `GlobalConfig.general.idle.timeouts`, whose upstream defaults lock after 180 seconds, turn DPMS off after 300 seconds, and run `systemctl suspend-then-hibernate` after 600 seconds. Because the mutable `~/.config/caelestia/shell.json` does not override this section, Caelestia can lock well before Hypridle and still contains an automatic idle sleep action.

## Acceptance Criteria
- [ ] Axiom's Caelestia settings declare `general.idle.timeouts` with a 900 second `lock` action and a 1800 second `dpms off` / `dpms on` action.
- [ ] Axiom's Caelestia settings contain no 600 second automatic sleep, suspend, hibernate, or `suspend-then-hibernate` idle action.
- [ ] Existing mutable `~/.config/caelestia/shell.json` is migrated on session startup so already-deployed Axiom sessions get the same idle policy instead of only newly seeded configs.
- [ ] Hypridle remains the checked-in 900 second lock and 1800 second DPMS policy with no automatic suspend listener.
- [ ] Axiom README and wiki current-truth entries explain that Caelestia and Hypridle are aligned and that no repository-owned automatic idle sleep is configured.
- [ ] Focused Nix/static validation proves the generated shell settings, migration helper, Hypridle values, and absence of automatic sleep actions.

## Assumptions
- The user's observed early lock is caused by Caelestia's upstream 180 second `general.idle.timeouts` default, not by a shorter active Hypridle timeout.
- Keeping both Caelestia and Hypridle at the same 900/1800 second thresholds is acceptable; duplicate lock/DPMS actions are idempotent for this policy.
- Axiom should continue enabling Caelestia Keep Awake / `idleInhibitor` as the visible shell UI state after session startup.
- Existing user customization in `~/.config/caelestia/shell.json` should be preserved outside the narrow launcher and idle policy fields owned by Axiom.

## Constraints
- Do not reintroduce `hyprlock`, `axiom-sleep-mode`, Power Mode launchers, a repository-owned sleep inhibitor service, or automatic idle suspend through Hypridle.
- Do not broaden logind or polkit permissions.
- Do not overwrite the whole mutable Caelestia shell config when a narrow JSON migration can preserve unrelated user settings.
- Use the Legion worktree PR lifecycle for implementation, verification, review, walkthrough, wiki writeback, and delivery.

## Risks
- If Caelestia's config schema changes, the `general.idle.timeouts` JSON shape may need a follow-up adjustment.
- Running live idle timing tests would disrupt the active desktop session, so primary validation should be static/Nix-backed with a post-deploy smoke check.
- Two aligned idle owners can emit the same lock/DPMS actions at the same thresholds; this is expected but should stay documented so future tasks do not misread the duplication as drift.

## Scope
- `hosts/axiom/default.nix`
- `hosts/axiom/README.org`
- `config/hypr/hypridle.conf` validation only
- `.legion/tasks/axiom-caelestia-idle-timeouts/**`
- `.legion/wiki/**` current-truth entries for Axiom idle policy

## Non-Goals
- Do not redesign Axiom's whole power policy or add a new user-facing toggle.
- Do not remove Caelestia Keep Awake startup enablement.
- Do not change the lock client away from Caelestia WlSessionLock.
- Do not run disruptive live idle, suspend, or hibernate tests from the tool session.
- Do not rewrite historical raw evidence for earlier completed Legion tasks.

## Design Summary
- Add Axiom-owned Caelestia `general.idle` settings that mirror Hypridle's 15 minute lock and 30 minute DPMS values and omit upstream's 600 second sleep action.
- Extend the existing Axiom Caelestia pre-start JSON migration so persisted shell configs receive the same idle policy while preserving unrelated user settings.
- Keep Hypridle unchanged as the repository-owned idle policy surface and document that Caelestia is deliberately aligned rather than left at upstream defaults.
- Validate through Nix evaluation of generated config/migration text plus focused searches for removed automatic sleep actions.

## Phases
1. Contract: capture the observed dual-idle-owner problem, scope, acceptance, assumptions, and worktree boundary.
2. Implementation: align Caelestia settings and migration helper, update active docs/wiki, and preserve Hypridle policy.
3. Verification: run targeted Nix/static checks and record validation evidence.
4. Review and delivery: record review, walkthrough, PR body, wiki writeback, and complete PR lifecycle.

---
*Created: 2026-05-28 | Updated: 2026-05-28*
