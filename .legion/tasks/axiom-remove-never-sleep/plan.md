# Axiom Remove Never Sleep

## Name
Axiom Remove Never Sleep

## Task ID
`axiom-remove-never-sleep`

## Goal
Remove the now-unneeded `axiom-caelestia-never-sleep` implementation, service wiring, and active documentation while preserving the user's updated Axiom idle lock and DPMS timing changes.

## Problem
Axiom previously added a session-scoped `systemd-inhibit` service to force a stronger never-sleep default. The workstation idle policy has now moved away from that requirement: Hypridle remains responsible for lock and DPMS timing, while the explicit never-sleep service should no longer be declared, built, documented, or treated as current truth.

## Acceptance Criteria
- [ ] `hosts/axiom/default.nix` no longer defines the generated `axiom-caelestia-never-sleep` script.
- [ ] `hosts/axiom/default.nix` no longer declares `systemd.user.services.axiom-caelestia-never-sleep`.
- [ ] Repository documentation no longer instructs users to check or stop `axiom-caelestia-never-sleep.service` as current Axiom behavior.
- [ ] Wiki current-truth entries are updated so Axiom idle policy is lock plus DPMS, with Caelestia Keep Awake retained only as the visible idle-inhibitor state.
- [ ] The user's Hypridle timeout changes are preserved in the delivered branch, with comments matching the configured seconds.
- [ ] Focused searches find no active config or docs still using `axiom-caelestia-never-sleep` outside historical task evidence.
- [ ] Targeted formatting and Nix validation pass, or any environment limitation is recorded.

## Assumptions
- The user's uncommitted Hypridle change is intentional: lock after 15 minutes and DPMS off after 30 minutes.
- Historical `.legion/tasks/axiom-caelestia-never-sleep-default/**` raw evidence can remain unchanged as historical evidence.
- Manual suspend capabilities, Caelestia power controls, and existing polkit allowlists are not being redesigned in this task.

## Constraints
- Do not restore `axiom-sleep-mode`, Power Mode launchers, Axiom-only Hypridle overrides, or any new sleep-inhibitor replacement.
- Do not broaden logind or polkit permissions.
- Do not modify unrelated untracked work in the main workspace.
- Use the Legion worktree PR lifecycle for implementation and delivery evidence.

## Risks
- Headless validation cannot prove live Hypridle reload behavior; live session smoke remains a post-deploy check.
- Removing the login1 inhibitor means manual or external sleep requests are no longer blocked by this service; that is intended but should be visible in docs.
- Wiki entries may still contain historical mentions; active-current-truth language must be distinguished from raw history.

## Scope
- `config/hypr/hypridle.conf`
- `hosts/axiom/default.nix`
- `hosts/axiom/README.org`
- `.legion/wiki/**` current-truth entries for Axiom power policy
- `.legion/tasks/axiom-remove-never-sleep/**`

## Non-Goals
- Do not remove Caelestia `idleInhibitor` startup enablement.
- Do not change lock implementation from `hyprlock`.
- Do not add an allow-sleep toggle or a replacement power-mode state machine.
- Do not rewrite historical Legion raw evidence for completed tasks.

## Design Summary
- Keep Hypridle as the active repository-owned idle policy surface and preserve the user's longer timeout values.
- Remove the declarative Nix service and generated script rather than disabling them conditionally, because the feature is no longer needed.
- Rewrite active README/wiki guidance to describe current behavior without the login1 sleep blocker.
- Validate by focused searches, diff whitespace checks, and targeted Nix evaluation/build evidence.

## Phases
1. Contract: capture scope, assumptions, acceptance, and worktree boundary.
2. Implementation: remove the service/script, preserve Hypridle timeout changes, and update active docs/wiki.
3. Verification: run focused string searches, `git diff --check`, and targeted Nix validation.
4. Review and delivery: record review, walkthrough, PR body, wiki writeback, and PR lifecycle state.

---
*Created: 2026-05-27 | Updated: 2026-05-27*
