# Axiom Remove Default Keep Awake

## Name
Axiom Remove Default Keep Awake

## Task ID
`axiom-remove-default-keep-awake`

## Goal
Stop Axiom from enabling Caelestia Keep Awake / `idleInhibitor` by default so the aligned 15 minute lock and 30 minute DPMS idle policy can run automatically.

## Problem
Axiom currently has a startup helper that retries `caelestia-shell ipc call idleInhibitor enable` after the Caelestia session starts. That makes Caelestia's Keep Awake state default on, which conflicts with the current desired behavior: Hypridle and Caelestia idle monitors should lock after 15 minutes, turn DPMS off after 30 minutes, and avoid automatic sleep without globally suppressing idle handling.

## Acceptance Criteria
- [ ] `hosts/axiom/default.nix` no longer defines the generated `axiom-caelestia-keep-awake` helper.
- [ ] `hosts/axiom/default.nix` no longer registers startup hook `07-caelestia-keep-awake` or otherwise runs `idleInhibitor enable` by default.
- [ ] Caelestia manual Keep Awake / `idleInhibitor` commands remain available to the user.
- [ ] Axiom's 900 second lock and 1800 second DPMS Caelestia/Hypridle idle policy remains unchanged.
- [ ] Active README and wiki current truth describe Keep Awake as manual, not default-enabled.
- [ ] Focused validation proves no active Axiom config still defaults `idleInhibitor enable`.

## Assumptions
- The user wants automatic lock/DPMS to work by default, not an always-on Keep Awake session.
- Caelestia's `idleInhibitor` remains useful as a manual UI toggle for temporary keep-awake behavior.
- Existing historical Legion task evidence can remain unchanged as historical raw evidence.

## Constraints
- Do not remove Caelestia itself, Caelestia WlSessionLock, or the manual `idleInhibitor` IPC entrypoints.
- Do not change the recently aligned 900/1800 Caelestia or Hypridle idle timers.
- Do not reintroduce automatic idle sleep, `axiom-sleep-mode`, a sleep-inhibitor service, or a power-mode state machine.
- Use the Legion worktree PR lifecycle for implementation and delivery evidence.

## Risks
- If a previous session left Keep Awake enabled persistently, removing the startup enable hook will not necessarily flip that existing runtime state off until the user toggles it or Caelestia state is reset.
- Live confirmation of idle lock timing is disruptive, so validation should be static/Nix-backed with a post-deploy smoke check.
- Wiki/task history contains prior default Keep Awake decisions; current-truth entries must distinguish manual behavior from historical defaults.

## Scope
- `hosts/axiom/default.nix`
- `hosts/axiom/README.org`
- `.legion/tasks/axiom-remove-default-keep-awake/**`
- `.legion/wiki/**` current-truth entries for Axiom power policy

## Non-Goals
- Do not change the 15 minute lock / 30 minute DPMS policy.
- Do not remove manual Caelestia Keep Awake controls.
- Do not change lock implementation from Caelestia WlSessionLock.
- Do not run live suspend, hibernate, or long idle timing tests from the tool session.
- Do not rewrite historical raw evidence for completed tasks.

## Design Summary
- Delete the Axiom-local `caelestiaKeepAwake` helper and its `07-caelestia-keep-awake` startup hook.
- Keep the Caelestia shell settings/migration that align `general.idle.timeouts` to 900/1800 with no sleep action.
- Update README and wiki current truth to treat Keep Awake as a manual toggle only.
- Validate with Nix assertions, focused searches, and host build evidence.

## Phases
1. Contract: capture scope, acceptance, non-goals, and worktree boundary.
2. Implementation: remove default Keep Awake wiring and update active docs/wiki.
3. Verification: run focused string/Nix/build checks and record evidence.
4. Review and delivery: record review, walkthrough, PR body, wiki writeback, and PR lifecycle state.

---
*Created: 2026-05-28 | Updated: 2026-05-28*
