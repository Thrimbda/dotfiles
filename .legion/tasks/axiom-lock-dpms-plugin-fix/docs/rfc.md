# RFC: Axiom Caelestia Lock DPMS Secure-State Arming And Native Wake

Status: Accepted | Risk: Standard

## Context And Evidence

The Config-plugin closure repair from PR #194 is deployed and loaded. The live
plugin exposes `lockDpmsTimeout`, the active configuration evaluates it as `60`,
and `hl.dsp.dpms({ action = "disable" })` changes both monitors to
`dpmsStatus: false`. The original timer failed to arm; after secure-state
arming was deployed, a manual lock left both monitors at `dpmsStatus: false`
after 65 seconds while Hyprland still reported `LOCK`.

The initial failure was the event that arms the timer. Caelestia currently
subscribes to `WlSessionLock.lockedChanged` in `IdleMonitors.qml`. Quickshell
0.3 declares that notify signal as `lockStateChanged`, but its source has an
asymmetric implementation:

- `WlSessionLock::setLocked(true)` creates the local session-lock object through
  `realizeLockTarget()` without emitting `lockStateChanged`.
- The compositor acknowledgement is connected to `secureStateChanged`, not
  `lockStateChanged`.
- `WlSessionLock::unlock()` emits `lockStateChanged`.

Qt resolves `onLockedChanged` through the property's notify signal, so the
current handler runs for unlock cleanup but not for lock arming. Quickshell's
`secure` property is the correct event boundary: it becomes true only after the
compositor confirms all screens are covered with lock surfaces.

Before native wake was enabled, the QML zero-timeout wake monitor did not restore DPMS
after physical local input. Axiom reports both `misc:key_press_enables_dpms`
and `misc:mouse_move_enables_dpms` as `false`, leaving no compositor-native
wake path.

## Goals

- Start one lock-scoped 60-second timer only after Caelestia has a secure,
  compositor-confirmed session lock.
- Preserve timer cancellation, DPMS restoration on unlock, and input wake
  without unlock or rearming within the same lock epoch.
- Keep the already-correct Config plugin closure and Axiom configuration.
- Restore Axiom DPMS through Hyprland's physical key-press and pointer-motion wake path.

## Non-goals

- Patching or upgrading Quickshell, adding an external idle daemon, or changing
  the 900/1800-second policy.
- Changing Caelestia's existing lock request entrypoints, other hosts,
  session-runner ownership, suspend, or hibernate.
- Retrying failed locks or making a timer action a substitute for a valid
  session lock.
- Adding lock-surface-specific input handlers or changing DPMS wake behavior on
  hosts other than Axiom.

## Options

| Option | Assessment | Decision |
| --- | --- | --- |
| Patch Quickshell to emit `lockStateChanged` when it acquires a lock. | Would correct the upstream notify contract but expands scope to a global framework package and its lifecycle. | Reject. |
| Add a Caelestia-owned request signal and route all five lock entrypoints through it. | Avoids the missing notify, but local `locked` state exists before compositor confirmation and requires unnecessary multi-file routing. | Reject. |
| Subscribe to `WlSessionLock.secureChanged` and arm only while `secure` is true. | Uses the native compositor-confirmation event, covers every existing lock path, and remains local to the current QML module. | Recommend. |

## Decision

Keep all existing lock request paths unchanged. In `IdleMonitors.qml`, separate
timer arming from unlock cleanup:

- `onSecureChanged` checks `root.lock.lock.secure` and invokes the existing
  lock-arming branch only when it is true.
- `onLockedChanged` invokes cleanup only when `root.lock.lock.locked` is false.
- The timer's existing lock, epoch, identity, and one-shot guards remain in
  place before it dispatches `dpms off`.

The `secureChanged` handler can fire again during unlock, but its false guard
prevents arming. If a future Quickshell version starts notifying `lockedChanged`
on lock acquisition, that event is ignored while `locked` is true; only
`secureChanged` with `secure === true` arms the timer. A rejected or not-yet-
secure lock never starts a timer.

For input wake, configure Axiom's existing `hl.config` `misc` block with
`key_press_enables_dpms = true` and `mouse_move_enables_dpms = true`. Hyprland
then restores DPMS before lock-screen input handling, so the lock remains active
and all existing lock paths inherit the same reliable behavior. The second
option is specifically pointer motion, not mouse-button input. The QML wake
monitor remains a harmless redundant restore path but is not the acceptance
mechanism.

## Native Wake Options

| Option | Assessment | Decision |
| --- | --- | --- |
| Rely only on the existing QML zero-timeout `IdleMonitor`. | Failed the physical-input smoke and depends on an idle-state transition after displays are disabled. | Reject. |
| Add QML pointer and keyboard handlers to lock-surface components. | Can be lock-scoped but duplicates compositor input ownership and requires multi-component event propagation. | Reject. |
| Enable Hyprland native key and mouse DPMS wake for Axiom. | The compositor receives physical input first, covers lock and fallback DPMS, and is an explicit user-approved host policy. | Recommend. |

## Correctness Criteria

| Property | Required proof |
| --- | --- |
| Confirmation gate | The only lock-arming route is `secureChanged` with an explicit true check. |
| Unlock behavior | The `lockedChanged` route only invalidates the epoch, destroys an active timer, and restores timer-owned DPMS after unlock. |
| Existing paths | No lock request source changes; successful shortcut, IPC, idle, sleep, and logind locks all converge on the same `WlSessionLock.secure` event. |
| Native wake | Axiom config enables Hyprland key-press and pointer-motion DPMS wake; other hosts remain unchanged. |
| Existing boundaries | The Config plugin property, Axiom value `60`, 900/1800 entries, and idle ownership are unchanged. |
| Runtime behavior | A deployed manual lock turns DPMS off after 60 seconds; physical input turns displays back on while it remains locked; unlocking leaves displays on. |

## Scope

Change the existing `IdleMonitors.qml` shell patch and focused source assertions,
plus Axiom's Hyprland `misc` host policy. Retain the Nix package integration and
Config-plugin patch. Update task-local design, verification, review, and
delivery evidence.

## Verification

- Apply the shell patch to the pinned source with `--fuzz=0` and run Node
  assertions for secure-gated arming, unlock-only cleanup, timer guards, wake
  behavior, and the retained plugin-schema assertion.
- Build the configured Caelestia package without running a Nix build on Acorn.
- On Axiom, restart Caelestia from the deployed closure, verify the loaded shell
  and plugin paths and the effective value `60`, then manually lock and sample
  `hyprctl -j monitors` after at least 60 seconds.
- While still locked, provide input and verify DPMS is on while lock state
  remains true; unlock manually and verify no timer-owned DPMS state remains.
- Verify `hyprctl getoption misc:key_press_enables_dpms` and
  `misc:mouse_move_enables_dpms` both report `true`, then test a physical key
  press and pointer motion in separate DPMS-off lock cycles.

## Rollback

Changing `lockDpmsTimeout` to `0` affects future secure locks only; it does not
cancel a timer that is already armed. For an active lock, first wake DPMS with
input if necessary, then manually unlock. Confirm `caelestia shell lock
isLocked` is false and every monitor reports `dpmsStatus: true`; the existing
unlock cleanup has then cancelled the timer and restored timer-owned DPMS.

Only after that confirmation, deploy the `lockDpmsTimeout = 0` configuration or
revert this shell-patch change, then allow the normal reload hook to restart
Caelestia. Confirm the restarted shell reads `0` before any subsequent lock.
Never deploy a shell restart, terminate QuickShell, or perform the package
rollback while a session lock is active.

To roll back native wake, follow the same unlocked-session rule, set both Axiom
Hyprland `misc` values to `false`, deploy, and confirm both `hyprctl getoption`
values are false before the next lock.
