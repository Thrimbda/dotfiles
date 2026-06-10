# RFC Review: Axiom Critical Network Resilience

## Review 1 - 2026-06-10

Result: FAIL

### Blocking Findings
- Autossh automatic remote cleanup is not sufficiently safe or rollbackable. The RFC allows killing a remote `sshd` listener on `127.0.0.1:2223`, but does not specify an implementable, verified parser/permission model for identifying only the stale forwarding listener. A mistaken kill is an irreversible remote side effect, not a normal Nix rollback.
- Autossh health verification is too weak for the stated goal. Reading an `SSH-2.0-` banner proves a listener speaks an SSH-like protocol, but not that the reverse path reaches `axiom` or is authenticated/usable. This may miss the active-but-broken mode the task is meant to fix.
- Verification does not cover the dangerous failure paths: autossh repeated-failure counter, remote listener classification, cleanup behavior, and restart sequencing. Unit-shape inspection plus a live happy-path banner check is not enough to verify automatic remote cleanup safely.

### Non-blocking Suggestions
- Make remote cleanup opt-in, dry-run first, or require manual approval/logging until parser behavior is proven.
- Add explicit tests or scripted simulations for healthcheck counters and restart thresholds.
- Clarify the exact SSH host key source/value and verify `/etc/ssh/ssh_known_hosts` use without touching user `known_hosts`.
- Keep the Clash GUI OOM fallback, but explicitly verify whether the generated user drop-in actually changes `OOMScoreAdjust`.
- Reconsider or justify `zramSwap.memoryPercent = 25`; it may be larger than small-buffer scope suggests.

### Resolution Plan
- Remove automatic remote process killing from the enabled healthcheck path.
- Strengthen autossh verification by comparing the SSH host key exposed through remote `127.0.0.1:2223` against `axiom`'s local SSH host public key.
- Treat remote stale listener cleanup as manual operational follow-up, not timer-driven automatic behavior.
- Add verification for healthcheck failure counters and restart thresholds.
- Cap zram more conservatively.

## Review 2 - 2026-06-10

Result: PASS

### Blocking Findings
None.

### Resolution Notes
- Automatic remote process killing is no longer part of enabled timer behavior.
- Autossh endpoint verification now compares the ED25519 key exposed through remote `127.0.0.1:2223` against `axiom`'s local SSH host key.
- Verification and rollback coverage are sufficient for implementation gate: build/unit-shape checks, healthcheck fake-input checks, key-comparison verification, live checks after approval, and rollback handles are all specified.

### Non-blocking Suggestions
- Remove any leftover wording that suggests a generic autossh banner check is the required verification.
- Pin the actual remote ED25519 host key in the implementation/review evidence.
- Ensure autossh healthcheck logs distinguish unreachable remote, host-key mismatch, no listener, and stale/wrong listener.
