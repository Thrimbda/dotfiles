# Review: Axiom Keep Awake Nonblocking Startup

## Verdict

PASS

## Findings

No blocking findings.

## Scope Review

- In scope: `hosts/axiom/default.nix` changes only how `07-caelestia-keep-awake` launches the existing helper.
- In scope: task docs and wiki record the nonblocking startup conclusion.
- Out of scope avoided: no Caelestia UI changes, no custom sleep mode, no Hypridle policy changes, no `caelestia-shell.service` restoration, no system-wide inhibitor, and no permission expansion.

## Correctness Review

- The existing 120-retry helper remains unchanged, so cold-start IPC coverage is preserved.
- The startup hook now invokes the helper through `nohup` and backgrounds it, so hook execution can continue immediately instead of waiting for IPC readiness.
- Output is redirected to `/dev/null`; this matches the previous `|| true` behavior where Keep Awake failure was non-blocking and not a hard startup failure.
- The command is idempotent: repeated `idleInhibitor enable` calls converge on enabled state.

## Security Lens

Security trigger considered: power/session control behavior.

Result: no new security concern. The change only adjusts process blocking behavior for an existing user-session IPC call. It does not widen polkit, does not add logind `ignore-inhibit`, and does not introduce privileged wrappers.

## Residual Risk

Live startup feel still requires a post-deploy Hyprland session smoke. Static validation proves the hook no longer waits in the foreground.
