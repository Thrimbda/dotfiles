# Axiom Keep Awake Nonblocking Startup

## Goal

Keep Axiom's default Caelestia Keep Awake behavior while preventing the retry helper from blocking the graphical startup hook chain.

## Problem

PR #59 correctly extended the Keep Awake helper retry window to cover Caelestia session cold-start IPC registration. That fixed the race, but `07-caelestia-keep-awake` still runs in the foreground from the startup hook. If `hey hook startup` is sequential, the helper can block later startup work for up to the retry window when Caelestia IPC is not ready yet. This matches the reported startup slowdown.

## Scope

- Run the existing `axiom-caelestia-keep-awake` helper asynchronously from the startup hook.
- Preserve the direct `caelestia-shell ipc call idleInhibitor enable` helper.
- Preserve the 120 retry attempts from the cold-start race fix.
- Update validation and wiki evidence.

## Non-Goals

- Do not change Caelestia UI behavior.
- Do not restore `axiom-sleep-mode`, Power Mode launchers, custom Hypridle overrides, or `systemd-inhibit` wrappers.
- Do not reintroduce `caelestia-shell.service`.
- Do not add headless/system-wide no-sleep policy.
- Do not widen polkit or logind permissions.

## Acceptance

- Evaluated `07-caelestia-keep-awake` starts the helper through `nohup` in the background.
- The helper still uses direct `caelestia-shell ipc call idleInhibitor enable` and `seq 1 120`.
- Startup hook ordering still runs `06-caelestia-shell` before `07-caelestia-keep-awake`.
- `git diff --check`, targeted Nix assertions, and Axiom toplevel build pass.

## Assumptions

- The helper is idempotent because repeated `idleInhibitor enable` calls converge on enabled state.
- Backgrounding the helper is acceptable because failure to enable Keep Awake should not block shell startup; post-deploy smoke still verifies the final state.

## Risk

Low. The behavior change is limited to startup hook blocking semantics. The actual Keep Awake IPC command and retry window remain unchanged.

## Phases

- Implement the startup hook backgrounding change.
- Validate generated hook/helper shape and build Axiom.
- Review scope/correctness/security.
- Write walkthrough/wiki evidence.
- Complete PR lifecycle.
