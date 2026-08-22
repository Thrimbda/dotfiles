## Summary

- Arm Caelestia's 60-second lock DPMS timer from compositor-confirmed
  `WlSessionLock.secureChanged`, not the missing Quickshell 0.3 lock-acquisition
  notification.
- Enable Axiom-only Hyprland key-press and pointer-motion DPMS wake so displays
  wake without unlocking the session.
- Keep the patched Config plugin closure, 900/1800 idle policy, Caelestia idle
  ownership, and all non-Axiom hosts unchanged.

## Validation

- PASS: zero-fuzz Config/shell patch application and focused Node assertions.
- PASS: patched Caelestia package build and full Axiom system build.
- PASS: generated Hyprland Lua and live `hyprctl getoption` both show native
  key and pointer wake enabled.
- PASS: locked session reaches DPMS-off at 65 seconds; pointer wake restores
  displays while `LOCK` remains active; another 65 seconds does not rearm.
- PASS: unlock from timer-owned DPMS-off restores displays and removes lock
  state.
- PASS: RFC and change reviews, including the session-lock security lens.

## Delivery Evidence

- `docs/test-report.md`
- `docs/review-rfc.md`
- `docs/review-change.md`
- `docs/report-walkthrough.md`
