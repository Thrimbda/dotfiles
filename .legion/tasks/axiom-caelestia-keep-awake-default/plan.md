# Axiom Caelestia Keep Awake Default

## Goal

Replace the custom Axiom no-sleep wrapper with Caelestia's built-in Keep Awake / `idleInhibitor` capability and enable it by default when the Axiom desktop session starts.

## Problem

The previous Axiom no-sleep implementation added a host-local `axiom-sleep-mode` script, separate launcher entries, a generated Hypridle override, and a user `systemd-inhibit` service. After inspecting Caelestia, the shell already provides a Keep Awake UI backed by `services/IdleInhibitor.qml` and IPC verbs such as `caelestia shell idleInhibitor enable`. Keeping a separate Axiom power mode duplicates the shell's visible state and can make the UI misleading.

## Acceptance

- [ ] Axiom no longer declares `axiom-sleep-mode`, `Power Mode:*` launcher entries, `axiom-no-sleep-inhibit.service`, or `axiom-sleep-mode-apply.service`.
- [ ] Axiom no longer overrides generated `hypr/hypridle.conf` solely to route suspend through `axiom-sleep-mode`.
- [ ] Axiom starts the Caelestia Keep Awake state by default through the repository-managed Hyprland/Caelestia session path.
- [ ] Caelestia's own Keep Awake UI remains the visible toggle surface; no separate desktop launcher is added for this task.
- [ ] Host README documents the Caelestia-backed `caelestia shell idleInhibitor ...` shell entrypoints and notes the graphical-session dependency.
- [ ] Focused Nix/static validation proves the custom wrapper is gone and the Caelestia idle inhibitor enable hook is present.
- [ ] Axiom toplevel build passes, or the strongest feasible blocker is recorded.

## Assumptions

- The active Axiom shell is Caelestia and its CLI package supports `caelestia shell idleInhibitor enable`.
- Keep Awake is a graphical-session idle inhibitor. It is the correct default for the desktop use case, but it is not a replacement for headless/system-wide sleep policy if no Hyprland/Caelestia session starts.
- The user wants Caelestia UI state to be the source of truth, not a second Axiom-specific mode state.

## Constraints

- Use `git-worktree-pr` lifecycle and deliver through PR.
- Keep the change scoped to Axiom/Caelestia idle behavior and related docs/wiki evidence.
- Do not redesign Caelestia UI or patch upstream QML.
- Do not widen polkit power permissions or add logind `ignore-inhibit` behavior.
- Preserve unrelated Axiom theme/Fcitx/OpenCode/remote-access changes already on `origin/master`.

## Risks

- Caelestia Keep Awake only applies while the graphical shell runs; if Axiom is headless or the session fails to start, it cannot enforce no-sleep.
- The upstream Keep Awake state is persistent through Caelestia's `PersistentProperties`; forcing `enable` on session startup intentionally makes the default on, but the user can still toggle it off after startup.
- Static validation can prove config and command wiring, but live Keep Awake UI state must be smoke-tested in the real Axiom session.

## Scope

- `hosts/axiom/default.nix`
- `hosts/axiom/README.org`
- `.legion/tasks/axiom-caelestia-keep-awake-default/**`
- `.legion/wiki/**` entries that currently describe Axiom no-sleep behavior

## Non-Goals

- Do not keep the custom `axiom-sleep-mode` mode system.
- Do not add new power-mode launcher entries.
- Do not implement system-wide/headless no-sleep policy.
- Do not change global `config/hypr/hypridle.conf` for other hosts.
- Do not run live suspend/hibernate tests in this session.

## Design Summary

Use Caelestia's native `idleInhibitor` as the single source of truth. Axiom should start the graphical session and then call `caelestia shell idleInhibitor enable` from the repository-owned session startup path. This keeps the Keep Awake UI and actual idle-inhibit state aligned, removes the custom wrapper/service/launcher layer, and makes the behavior dependent on the same Caelestia session that owns the visible toggle.

## Design-Lite

The implementation is a small replacement rather than a new mechanism. The previous custom no-sleep design is superseded because upstream Caelestia already exposes the required capability through IPC and UI. Rollback is a git revert; operationally, the user can toggle Keep Awake off in Caelestia or run `caelestia shell idleInhibitor disable` after deploy.

## Phases

1. Brainstorm: materialize stable follow-up contract.
2. Engineer: replace custom no-sleep wiring with Caelestia Keep Awake startup enablement.
3. Verify Change: run targeted Nix/static checks and Axiom build.
4. Review Change: assess scope, correctness, and session/power safety.
5. Report Walkthrough: produce PR-ready summary.
6. Legion Wiki: update current decisions/patterns/maintenance to supersede the custom wrapper.
7. PR Lifecycle: commit, push, create/track PR, cleanup, and refresh main workspace when possible.
