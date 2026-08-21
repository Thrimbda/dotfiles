# Delivery Walkthrough: Lock-Scoped DPMS Timeout for Axiom

Mode: implementation

## Delivered Behavior

- Axiom sets `general.idle.lockDpmsTimeout = 60` through both Caelestia settings paths. The focused upstream patch starts its one-shot delay from the observed false-to-true `WlSessionLock.locked` transition, rather than from a lock command or last input.
- The typed upstream default is `0`; without an explicit host setting, other hosts leave this feature disabled.
- After timer-owned DPMS-off, input uses the existing `dpms on` action without changing `locked`. The wake path does not create or re-arm a timer in the same lock epoch.
- The existing 900-second lock and 1800-second `dpms off`/`dpms on` policy remains unchanged. Hypridle remains disabled on Axiom.

## Evidence

- Focused static validation passed: the patch applies to pinned Caelestia source with `--fuzz=0`, and the Node assertions cover the lock observer, per-epoch timer, stale-callback guards, input wake, and no-rearm behavior (`docs/test-report.md:13-16,29-50`).
- Effective Axiom configuration evaluation passed: both settings paths resolve to `60`, the 900/1800 entries remain, Hypridle is disabled, and no suspend or hibernate action is introduced (`docs/test-report.md:52-85`).
- The ordinary Git-backed package build passed: `nix build --no-link .#nixosConfigurations.axiom.config.modules.desktop.caelestia.package` compiled the patched package (`docs/test-report.md:87-105`).
- Change review found no blocking correctness, security, maintainability, or scope issues and concluded PASS (`docs/review-change.md:5-42`).

## Residual Live Checks

No deployed graphical-session smoke test or deployment ran. Before claiming runtime DPMS behavior, verify on a deployed Axiom session:

- Direct IPC lock, the 900-second idle lock, and `loginctl lock-session` each begin the 60-second delay.
- Early unlock cancels a pending delay; rapid unlock/relock rejects an old timer callback.
- Physical input wakes all affected displays after timer-owned DPMS-off while `WlSessionLock` remains active.
- ext-idle delivery, Hyprland/compositor DPMS behavior, and existing audio/Keep Awake inhibition remain non-disruptive.
