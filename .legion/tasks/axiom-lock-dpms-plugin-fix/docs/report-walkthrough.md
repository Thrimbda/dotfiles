# Delivery Walkthrough: Axiom Caelestia Lock DPMS Behavior

Mode: implementation

## Outcome

Axiom now turns both displays off 60 seconds after a compositor-confirmed
Caelestia lock. Physical keyboard input or pointer motion wakes the displays
through Hyprland without releasing the lock, and the same lock epoch does not
start another timer.

## What Changed

- The shell patch listens for `WlSessionLock.secureChanged` to arm lock DPMS.
  This bypasses Quickshell 0.3's missing `lockedChanged` notification on lock
  acquisition while retaining native unlock cleanup.
- Axiom's Hyprland `misc` policy enables `key_press_enables_dpms` and
  `mouse_move_enables_dpms`. The compositor, rather than a lock-surface input
  handler, owns reliable physical-input wake.
- The focused QML test now requires secure-gated arming and unlock-only cleanup.
- The prior Config plugin closure fix remains active: the running shell maps the
  patched Config plugin and reads `lockDpmsTimeout = 60`.

## Evidence

- Clean patch application with `--fuzz=0`, Node assertions, package build, full
  Axiom build, generated Lua evaluation, and `git diff --check` passed.
- Runtime confirms both Hyprland wake options are `true`, a single patched shell
  is running, and the patched Config plugin is mapped into it.
- At 65 seconds of a locked session, both monitors reported DPMS off with
  Hyprland `LOCK` active.
- A virtual pointer move restored both monitors while `LOCK` and lock IPC state
  remained true; another 65 seconds left displays on and lock state true.
- A separate DPMS-off cycle followed by authorized local unlock restored both
  monitors and removed the lock state.

## Boundaries

- The Axiom-wide native wake policy also wakes the existing 1800-second DPMS
  fallback. This was explicitly approved.
- Idle durations, Caelestia ownership, other hosts, suspend, hibernate, and
  authentication behavior are unchanged.
- Temporary authentication suppression used only for controlled testing was
  restored to `true` and removed from final source.

See `docs/test-report.md` for commands and raw runtime evidence, and
`docs/review-change.md` for the readiness decision.
