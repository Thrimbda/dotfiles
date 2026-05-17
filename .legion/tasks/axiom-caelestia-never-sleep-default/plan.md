# Axiom Caelestia Never Sleep Default

## Name

Axiom Caelestia Never Sleep Default

## Task ID

`axiom-caelestia-never-sleep-default`

## Goal

Make the Axiom Caelestia desktop default to a never-sleep state so the workstation does not automatically suspend after idle and does not accept session sleep while the graphical desktop is active.

## Problem

The current Axiom configuration starts Caelestia and then enables Caelestia's `idleInhibitor` IPC state. Runtime feedback says Axiom can still sleep, which means the current default only covers part of the idle path and is not strong enough for the user's requested never-sleep default. Axiom needs a repository-managed Caelestia-session default that keeps the visible Caelestia Keep Awake state enabled and also blocks login1 sleep for the active graphical session.

## Acceptance

- Axiom still enables Caelestia's `idleInhibitor` by default after the Caelestia session starts.
- Axiom also starts a repository-managed sleep inhibitor by default with the Hyprland/Caelestia graphical session.
- The inhibitor blocks `sleep` through systemd/logind while the graphical session is active, so idle-triggered and direct session sleep requests do not suspend the machine by default.
- The change is scoped to the `axiom` host and does not change other hosts or global Hypridle defaults.
- The old custom `axiom-sleep-mode` toggle system and Power Mode launcher entries are not reintroduced.
- Host documentation explains that Axiom's Caelestia session defaults to never sleep and names the live checks for Caelestia Keep Awake plus the sleep inhibitor.
- Focused Nix/static validation proves the Caelestia keep-awake startup hook and the sleep inhibitor are present.
- Axiom toplevel build passes, or the strongest feasible blocker is recorded with evidence.

## Assumptions

- The requested "never sleep" default is stronger than Caelestia's UI-only idle inhibitor and should block sleep while the Axiom graphical desktop is active.
- A graphical-session-scoped user inhibitor is acceptable; this task does not need to enforce headless boot no-sleep behavior before login.
- Repeated Caelestia `idleInhibitor enable` calls remain idempotent and should stay as the UI state source of truth.
- Blocking manual suspend from the active session is intentional for the default state because the user asked for never sleep.

## Constraints

- Follow Legion workflow and use the git-worktree PR envelope for production changes.
- Keep production changes focused on `axiom` Caelestia/session power behavior and related host docs.
- Do not redesign or patch upstream Caelestia QML.
- Do not widen polkit power permissions or grant login1 `ignore-inhibit` behavior.
- Do not reintroduce the older custom sleep-mode toggle and launcher surface.

## Risks

- A session sleep inhibitor can also block intentional suspend actions until the user stops the graphical session or the service is stopped.
- Static validation can prove declarative wiring, but a live Axiom session is still needed to confirm final runtime inhibitor state and long-idle behavior.
- The fix must not regress Caelestia startup by making keep-awake setup block the ordered startup hook chain.

## Scope

- `hosts/axiom/default.nix`
- `hosts/axiom/README.org`
- `.legion/tasks/axiom-caelestia-never-sleep-default/**`
- `.legion/wiki/**` entries needed to update the durable current truth for Axiom sleep behavior

## Non-Goals

- Do not disable sleep globally for all NixOS hosts.
- Do not implement a new UI toggle or restore Power Mode launchers.
- Do not change global `config/hypr/hypridle.conf` for other hosts.
- Do not add headless/system-wide pre-login no-sleep policy.
- Do not run live suspend, reboot, or destructive power tests from this tooling session.

## Design Summary

Keep Caelestia's native Keep Awake / `idleInhibitor` as the visible UI state, but add an Axiom-local graphical-session sleep inhibitor as the enforcement layer for the stronger never-sleep default. The inhibitor should be owned by the same Hyprland/Caelestia session lifecycle so it is active for desktop use, stops with the session, and avoids broad system policy changes. This supersedes the failed assumption that Caelestia's idle inhibitor alone is enough to guarantee no sleep.

## Phases

1. Brainstorm: materialize this stable follow-up contract.
2. Design Gate: record and review a short RFC because this changes session sleep semantics after a prior incomplete fix.
3. Engineer: implement the reviewed minimal Axiom-local Caelestia/session inhibitor wiring and docs.
4. Verify Change: run focused static/Nix validation and the strongest feasible Axiom build.
5. Review Change: assess scope, correctness, and power/session safety.
6. Report Walkthrough: produce reviewer-facing summary and PR body.
7. Legion Wiki: update durable current truth and supersede the weaker idle-inhibitor-only behavior.
8. PR Lifecycle: commit, push, create/track PR, clean up worktree, and refresh the main workspace when possible.

---

Created: 2026-05-17
