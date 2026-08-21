# RFC: Lock-Scoped DPMS Timeout for Axiom

Status: Proposed | Risk: Standard

## Context And Evidence

- `hosts/axiom/modules/caelestia.nix` keeps independent Caelestia idle entries: lock at 900 seconds and `dpms off`/`dpms on` at 1800 seconds. Its shared `idleSettings` is written through both `settings` and `mutableConfig.settings`.
- `hosts/axiom/default.nix` sets `hypridle.enable = false`; Caelestia is therefore Axiom's sole automatic idle-policy owner.
- Manual direct lock uses `caelestia shell lock lock` through the Hyprland binding and compatibility script. The repository also has a `loginctl lock-session` path in the power menu.
- The pinned `caelestia-dots/shell` revision is `046dd3c6c3b1782f27284d5fc0e181b6021dd7c7`, and `modules/desktop/caelestia.nix` already registers a focused source patch.
- In that pinned source, `modules/IdleMonitors.qml` owns `handleIdleAction`, declares `required property Lock lock`, and maps `SessionManager.onLockRequested` to `root.lock.lock.locked = true`. `Lock.qml` direct IPC and the 900-second idle lock also set that same `WlSessionLock.locked` property.
- `IdleMonitor` measures user inactivity rather than DPMS state. Its documented zero timeout reports idle immediately, and `respectInhibitors: false` observes user input independently of idle inhibitors. The 1800-second monitor's `returnAction` cannot reliably wake a display blanked by a separate 60-second timer.

## Goals

- Turn DPMS off 60 seconds after a successful manual, automatic-idle, or SessionManager/logind WlSessionLock transition, provided the lock remains active.
- Explicitly wake DPMS on the next user input while preserving the lock.
- Prevent every stale timer callback, including an expiry queued across unlock and rapid relock.
- Preserve the 900/1800 global idle policy, audio inhibition, Keep Awake semantics, and Caelestia-only ownership.

## Non-goals

- Adding Hypridle, a host timer wrapper, suspend, hibernate, or another idle owner.
- Changing another host's effective behavior.
- Re-arming the 60-second timer after display wake while the same lock epoch remains active.
- Claiming live graphical-session verification in this RFC.

## Options

| Option | Assessment | Decision |
| --- | --- | --- |
| Wrap only manual lock commands with a 60-second host timer. | Misses the 900-second idle and SessionManager/logind paths; tracks command invocation rather than lock state and requires a separate cancellation owner. | Reject. |
| Change global DPMS from 1800 to 960 seconds. | Global monitors start from last input, not lock entry. Manual locks and unlock cancellation remain incorrect, and normal unlocked idle behavior changes. | Reject. |
| Patch pinned `IdleMonitors.qml` and `GeneralIdle`; enable the setting only on Axiom. | Reuses the callable DPMS action owner and observes every supported lock path at one property boundary. A default of `0` leaves the shared patch inert elsewhere. | Recommend. |
| Re-arm after every DPMS wake while still locked. | Needs additional input/wake lifecycle state and risks loops. The contract only requires wake without unlock, not a repeating post-wake blanking policy. | Reject. |

## Decision

Add `int lockDpmsTimeout = 0` to pinned upstream `plugin/src/Caelestia/Config/generalconfig.hpp`. Values less than or equal to zero disable the feature. Register a focused patch that changes pinned upstream `modules/IdleMonitors.qml`, not `Lock.qml`.

`IdleMonitors.qml` will observe `root.lock.lock.locked` and retain `handleIdleAction` as the sole action seam. On a valid timeout it calls `handleIdleAction("dpms off")`; the explicit wake monitor calls `handleIdleAction("dpms on")`. No host command, duplicate DPMS implementation, or dependency on the unrelated 1800-second `returnAction` is introduced.

Axiom alone sets `general.idle.lockDpmsTimeout = 60` in both existing settings paths. The 900-second lock and 1800-second DPMS entries remain independent fallback policy. The global 1800-second monitor can still act according to its own last-input deadline, but it does not arm, wake, cancel, or reset the lock-scoped mechanism.

## Lock Convergence

| Entry path | State boundary observed by the patch |
| --- | --- |
| Direct `Lock.qml` IPC, including the Hyprland keybinding | The IPC sets `WlSessionLock.locked = true`; the `IdleMonitors.qml` lock-property observer sees the false-to-true transition. |
| Caelestia's 900-second idle action | Existing `handleIdleAction("lock")` reaches the same `root.lock.lock.locked = true` property; the observer sees that transition. |
| `SessionManager.onLockRequested`, including `loginctl lock-session` | The existing handler assigns `root.lock.lock.locked = true`; the same observer sees that transition. |
| Repeated lock request while already locked | No false-to-true property transition occurs, so no second timer is created and the deadline is not reset. |

## State, Cancellation, And Wake Semantics

The patch owns these local `IdleMonitors.qml` state values:

- A monotonically increasing `lockEpoch`.
- One `activeLockDpmsTimer`, dynamically created for each false-to-true transition.
- A `dpmsOffEpoch` marker and a disabled-by-default explicit input wake `IdleMonitor`.

Each dynamically created QML `Timer` receives its epoch when constructed and that token is never changed. The timer is never reused for a later lock. Its expiry callback receives both its immutable token and object identity.

| Event | Required behavior |
| --- | --- |
| `locked` changes false to true | Increment `lockEpoch`, create and start one 60-second timer with that immutable epoch when `lockDpmsTimeout > 0`, and leave the wake monitor disabled. |
| Timer expiry | Proceed only if the lock is still true, the immutable token equals `lockEpoch`, and the timer is still `activeLockDpmsTimer`. Call `handleIdleAction("dpms off")`, record `dpmsOffEpoch`, then retire that timer and enable the wake monitor. |
| User input after timer-owned DPMS off | The enabled wake monitor uses `timeout: 0` and `respectInhibitors: false`. On its input-driven transition to `isIdle == false`, it verifies current lock and epoch, calls `handleIdleAction("dpms on")`, then disables itself and clears `dpmsOffEpoch`. It never changes `locked`, creates a timer, or re-arms the completed timer. |
| `locked` changes true to false | Increment `lockEpoch` before accepting further work, stop and destroy `activeLockDpmsTimer`, disable the wake monitor, and clear `dpmsOffEpoch`. A queued old callback retains its old immutable token and fails the state, epoch, and identity guards after a relock. |
| Input before timer expiry | It neither unlocks nor resets the 60-second deadline. Only leaving the locked state cancels the timer. |

The wake monitor is enabled only after this feature has successfully requested DPMS off for the current epoch. Ignoring inhibitors is limited to observing input for that wake action; existing global idle monitors retain their current inhibitor behavior. After a wake, the session remains locked and the feature does not re-arm until a real unlock followed by a new lock.

## Scope

Planned implementation is limited to:

- Axiom's two `lockDpmsTimeout = 60` settings in `hosts/axiom/modules/caelestia.nix`.
- The typed upstream config property, a focused `IdleMonitors.qml` patch, and patch registration in `modules/desktop/caelestia.nix`.
- Focused source/static coverage and later targeted session checks.

It must not change other hosts' settings, enable Hypridle, alter the 900/1800 entries, add a host wrapper, add suspend/hibernate, or modify the separate lock clients and commands beyond verifying their convergence.

## Verification

Verification is planned only; no live graphical-session result is claimed here.

- Confirm the patch applies to the pinned revision and that `GeneralIdle` exposes `int lockDpmsTimeout = 0` to `IdleMonitors.qml`.
- Add source/static coverage proving a dynamically created per-epoch timer, immutable epoch token, timer identity guard, duplicate-lock idempotence, and queued-expiry rejection across unlock then relock.
- Assert all lock convergence wiring: `Lock.qml` IPC, `handleIdleAction("lock")` for the 900-second path, and `SessionManager.onLockRequested` each reach the observed `root.lock.lock.locked` transition.
- Assert the explicit, initially disabled wake `IdleMonitor` has `timeout: 0`, `respectInhibitors: false`, is enabled only after timer-owned DPMS off, invokes `handleIdleAction("dpms on")` on input without unlocking, and does not re-arm the timer or rely on the 1800-second `returnAction`.
- Evaluate the effective Axiom configuration on an approved build host according to repository policy: 60-second lock timeout in both settings paths, unchanged 900/1800 entries, `hypridle.enable = false`, no automatic suspend/hibernate, and default-disabled behavior for other hosts.
- In a later deployed graphical-session check, exercise direct IPC, 900-second idle, and `loginctl lock-session`; early unlock; rapid unlock/relock; and input wake after 60 seconds. Confirm the display wakes while `isLocked` remains true and stale epochs cannot blank a new or unlocked session.

## Rollback

For immediate behavioral rollback, deploy `lockDpmsTimeout = 0` through both Axiom settings paths and restart the Caelestia session. Both writes are required because `mutableConfig` deep-merges into persistent `shell.json`; deleting the Nix attribute alone can leave a prior value of `60` behind.

After disabled behavior is confirmed, remove the persisted `general.idle.lockDpmsTimeout` key before removing the source patch, or retain the inert default-disabled patch. Do not rely on an unknown-config-key behavior after removing the typed property. No data migration, other-host rollback, or power-policy cleanup is needed.
