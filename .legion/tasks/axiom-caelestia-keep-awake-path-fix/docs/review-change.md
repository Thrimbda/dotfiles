# Review: Axiom Caelestia Keep Awake Path Fix

## Verdict

PASS

## Findings

No blocking findings.

## Scope Review

- In scope: `hosts/axiom/default.nix` changes only the Keep Awake helper command path.
- In scope: task docs and wiki summarize the runtime regression and validation evidence.
- Out of scope avoided: no custom `axiom-sleep-mode` restoration, no Hypridle policy changes, no new headless/system-wide inhibitor, and no polkit/logind permission expansion.

## Correctness Review

- The previous helper used the Caelestia Python CLI by absolute path, but that CLI shells out to `caelestia-shell` by name.
- The generated user unit has a minimal NixOS service `PATH`, so `caelestia-shell` lookup failed at runtime.
- The new helper directly invokes `${config.modules.desktop.caelestia.package}/bin/caelestia-shell ipc call idleInhibitor enable`, which removes the failing subprocess lookup while preserving the same Caelestia IPC target.
- The retry loop and final attempt behavior are unchanged.

## Security Lens

Security trigger considered: power/session control behavior.

Result: no new security concern. The change does not widen polkit, does not add logind `ignore-inhibit`, does not introduce sudo or privileged wrappers, and remains scoped to the user's graphical Caelestia session IPC.

## Residual Risk

Live post-deploy smoke is still required after switching the host generation because static validation cannot prove a future login's Wayland display environment. The current-session manual IPC check already confirmed the running shell accepts the direct command when called with the active display environment.
