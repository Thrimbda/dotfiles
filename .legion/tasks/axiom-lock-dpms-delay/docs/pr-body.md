## Summary

- Add an Axiom-only, lock-scoped 60-second DPMS-off delay triggered by the observed `WlSessionLock.locked` transition.
- Keep other hosts disabled by the upstream `lockDpmsTimeout = 0` default.
- Wake DPMS on input without unlocking or re-arming the delay in the same lock epoch.
- Preserve Axiom's 900-second lock and 1800-second DPMS policy, with Hypridle still disabled.

## Validation

- PASS: focused Node static assertions and clean `--fuzz=0` patch application against the pinned Caelestia source (`docs/test-report.md:13-50`).
- PASS: effective Axiom configuration evaluation confirms both 60-second settings, retained 900/1800 policy, disabled Hypridle, and no suspend/hibernate idle action (`docs/test-report.md:52-85`).
- PASS: `nix build --no-link .#nixosConfigurations.axiom.config.modules.desktop.caelestia.package` (`docs/test-report.md:87-105`).
- PASS: change review reports no blocking correctness, security, maintainability, or scope findings (`docs/review-change.md:5-42`).

## Not Run

No deployed graphical-session smoke test or deployment ran. Remaining live checks: direct IPC, 900-second idle, and `loginctl lock-session` lock paths; early unlock; rapid unlock/relock; physical-input DPMS wake while the lock remains active; ext-idle/compositor behavior; and audio/Keep Awake interaction.
