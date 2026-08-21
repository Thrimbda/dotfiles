# Delivery Walkthrough: Axiom Caelestia DPMS Plugin Closure Fix

Mode: implementation

## Root Cause

The prior shell derivation shipped the `IdleMonitors.qml` lock-DPMS patch, but
its separate `Caelestia.Config` C++ plugin was still the unpatched upstream
derivation. The QML therefore referenced `lockDpmsTimeout` while the plugin
loaded by the shell did not provide that configuration property. The shell QML
and Config schema came from different derivations.

## Fix

- Split the former combined patch at the upstream derivation boundary. The
  Config-only patch adds `GeneralIdle.lockDpmsTimeout` to
  `generalconfig.hpp`; the shell-only patch retains the existing QML timer
  logic in `IdleMonitors.qml` without changing its behavior.
- Capture the original plugin before either override, apply the Config patch to
  that plugin, and apply only the QML patch to the shell.
- Replace the original direct shell `buildInputs` plugin by resolved store path,
  assert that exactly one input matches, and expose the same patched derivation
  as `passthru.plugin`. Other inputs and passthru fields are preserved.

This makes the built shell's direct dependency and public plugin value identify
the same patched Config plugin (`docs/review-change.md:15-34`).

## Passed Build And Closure Proof

- The configured package build passed:
  `nix build --no-link .#nixosConfigurations.axiom.config.modules.desktop.caelestia.package`
  (`docs/test-report.md:34-50`).
- The built plugin's `caelestia-config.qmltypes` registers
  `caelestia::config::GeneralIdle.lockDpmsTimeout` with type `int`
  (`docs/test-report.md:24-32`; `docs/review-change.md:35-39`).
- Configured-package assertions found exactly one patched plugin direct input,
  zero original plugin direct inputs, and a `pkg.plugin` value resolving to the
  patched output (`docs/test-report.md:53-69`).
- The built shell has one direct reference to the patched plugin and no
  reference to the original plugin; review-time requisites inspection likewise
  excluded the original plugin (`docs/test-report.md:69`; `docs/review-change.md:28-34`).
- Both the RFC and implementation reviews passed with no blocking findings.
  The implementation review records one non-blocking future hardening item:
  bound the qmltypes test match to its enclosing component
  (`docs/review-rfc.md:7-64`; `docs/review-change.md:46-53`).

## Deployment And Live-Test Boundary

Deployment and live validation are blocked because the local non-interactive
authorization check, `sudo -n true`, requires a sudo password
(`docs/test-report.md:71-83`). No `nixos-rebuild switch`, Caelestia restart,
runtime import-path inspection, or lock/DPMS test was attempted.

Accordingly, this delivery makes no claim that a running QML engine selected
the patched plugin by import-path order, and no claim that physical DPMS turns
off after 60 seconds or wakes while the session remains locked.

After an approved deployment, restart Caelestia; record the loaded
`libcaelestia-configplugin.so` path from the shell process with the original
path absent; confirm the active value is `60`; then manually lock, wait 60
seconds, and check DPMS-off plus input wake with `WlSessionLock` still active
(`docs/test-report.md:85-89`; `docs/review-change.md:70-83`).
