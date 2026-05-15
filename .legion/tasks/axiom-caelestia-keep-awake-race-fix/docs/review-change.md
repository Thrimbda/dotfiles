# Review: Axiom Caelestia Keep Awake Race Fix

## Verdict

PASS

## Findings

No blocking findings.

## Scope Review

- In scope: `hosts/axiom/default.nix` changes only the retry count for the existing Keep Awake helper.
- In scope: task docs and wiki summarize the startup race and validation evidence.
- Out of scope avoided: no return to `caelestia-shell.service`, no custom sleep mode, no Hypridle policy change, no system-wide inhibitor, and no polkit/logind permission expansion.

## Correctness Review

- The existing helper is idempotent: repeated `idleInhibitor enable` calls converge on the same enabled state.
- The observed failure is timing-related: Caelestia registered IPC about 11 seconds after session startup, while the helper retried for about 10 seconds.
- Extending the retry loop to about 60 seconds addresses normal cold-start variance without changing the steady-state behavior.
- The generated hook ordering still starts `caelestia-session` before Keep Awake.

## Security Lens

Security trigger considered: power/session control behavior.

Result: no new security concern. The change only lengthens retries for an existing user-session IPC call. It does not widen polkit, does not add logind `ignore-inhibit`, does not introduce sudo or privileged wrappers, and remains scoped to the graphical Caelestia session.

## Residual Risk

Static validation cannot prove a future login's exact cold-start duration. A post-deploy Hyprland session smoke remains required, but the 60-second retry window is materially above the observed 11-second registration time.
