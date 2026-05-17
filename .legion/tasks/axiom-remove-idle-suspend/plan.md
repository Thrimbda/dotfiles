# Axiom Remove Idle Suspend

## Goal
Remove Axiom's automatic Hypridle-triggered suspend while preserving idle lock and DPMS screen-off behavior.

## Problem Statement
Axiom currently locks after 5 minutes, turns displays off after 10 minutes, and suspends after 15 minutes of idle time. The desired default is no automatic idle suspend from Hypridle, so the workstation can keep running after lock/screen-off without relying on Keep Awake state to mask the suspend listener.

## Acceptance Criteria
- [x] `config/hypr/hypridle.conf` keeps the 5 minute lock listener.
- [x] `config/hypr/hypridle.conf` keeps the 10 minute DPMS off/on listener.
- [x] `config/hypr/hypridle.conf` contains no `$suspend_cmd`, `systemctl suspend`, `loginctl suspend`, or `timeout = 900` idle suspend listener.
- [x] Axiom NixOS toplevel still builds.
- [ ] Delivery goes through the worktree PR lifecycle.

## Assumptions / Constraints / Risks
- Assumption: Manual suspend paths and Caelestia/logind power controls are outside this task unless explicitly reopened.
- Constraint: Do not restore `axiom-sleep-mode`, Power Mode launcher entries, Axiom Hypridle overrides, or `systemd-inhibit` wrappers as part of this removal.
- Constraint: Do not broaden polkit or logind permissions.
- Risk: A headless build cannot prove live Hypridle reload behavior; post-deploy smoke should inspect the active Hypridle config/logs.

## Key Points
- Hypridle policy: Hypridle should only lock and manage DPMS on idle.
- Scope control: This is a removal of the idle suspend trigger, not a redesign of system power controls.
- Rollback: Revert this change to restore the previous 15 minute automatic suspend listener.

## Scope
- `config/hypr/hypridle.conf` - remove the automatic suspend command/listener.
- `.legion/tasks/axiom-remove-idle-suspend/` - task evidence.
- `.legion/wiki/` - current-truth summary and Axiom idle policy notes.

## Phase Overview
1. Restore task contract and confirm idle policy scope.
2. Remove the Hypridle automatic suspend listener.
3. Validate grep scope, formatting, and Axiom toplevel build.
4. Record review/report/wiki evidence and deliver through PR.

---
*Created: 2026-05-18 | Updated: 2026-05-18*
