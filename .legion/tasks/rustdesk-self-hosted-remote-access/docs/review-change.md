# Review Change: RustDesk self-hosted remote access

> **Verdict**: **PASS - ready for the configuration PR**
> **Review target**: `origin/master` `0d61c714` through feature HEAD `3db55d1c`
> **Scope**: Configuration readiness only; production deployment remains gated
> **Security lens**: Secret handling, root services, IPC/process identity, signed app lifecycle, ingress, state publication, rollback
> **Date**: 2026-07-12

## Findings

No blocking correctness, security, scope, or maintainability finding remains.

The final review covered all five feature commits, the Round 7 RFC, generated helpers, failure/state tests, and target-native Charlie evidence. The branch was clean, rebased on live `origin/master`, ahead 5/behind 0, and passed `git diff --check`.

## Review Results

- **Source and artifacts**: Axiom source and cargo vendor are both pinned to RustDesk 1.4.9. Charlie pins the official ARM64 1.4.9 DMG and validates bundle id, Team ID, deep/strict signature, and Gatekeeper origin.
- **Acorn topology**: RustDesk Server 1.1.14 uses a separate agenix key, fail-closed key preflight, `-k _`, and only TCP 21115-21117 plus UDP 21116.
- **Provision state machine**: Reservation is durably published before secret access. Password invocation is one-shot and requires exact `Done!\n`; both auth-serving processes are replaced, public state is re-proved, and provision publishes ready but never stamp.
- **Manual finalization**: Finalizers require exact `--confirm-remote-auth`, share the operation lock, revalidate reservation/ready/process identities, read no secret, and invoke no password API.
- **Service lifecycle**: Axiom provision has only `Wants=` and `After=` on the main service and preserves replacement-capable `ExecStop`. Charlie app activation is locked, signature-gated, rollback-aware, idempotent for an identical verified bundle, and unloads old provision before transitions.
- **Security result**: PASS within the approved single-owner/manual-finalize threat model. No unaccepted secret exposure, privilege-boundary bypass, artifact-substitution path, or false rollback claim was found.

## Evidence

- Final Acorn output: `/nix/store/lbhi1fgapnhqj3z9xsajbcqg1bp17l8s-nixos-system-acorn-25.11.20260630.b6018f8`.
- Final Axiom output: `/nix/store/vq8y7x0bi84cpx9hp3yfcg82d6niy8pf-nixos-system-axiom-25.11.20260630.b6018f8`; effective RustDesk is 1.4.9.
- Final Charlie output: `/nix/store/9g2l5777jh51q9wzrr5yvywymgz6pmym-darwin-system-25.11.ebec37a` built on Charlie from exact commit `3db55d1c`.
- Charlie final system references `/nix/store/ll7kiyvhxzqs0j9clqf66a08s262szq0-rustdesk-macos-1.4.9/Applications/RustDesk.app`: arm64, version 1.4.9, bundle id `com.carriez.rustdesk`, Team `HZF9JMC8YN`, valid Notarized Developer ID signature and expected origin.
- Generated launchctl parser passed real complete Charlie output for two-argument server and three-argument service shapes while ignoring nested coalition state. Generated scripts, state/failure matrices, fallback controls, and finalizer zero-secret assertions passed.

## Deployment Gates

1. Deploy only from the clean merged commit, never a feature or Charlie verification worktree.
2. Verify DNS, Aliyun security group allow/deny rules, Acorn listeners/keypair/services, and relay ownership.
3. Verify actual systemd/launchd lifecycle, Charlie destination signature, PID replacement, and public configuration.
4. From a fresh controller, prove the new password succeeds and old, wrong, and cross-host passwords are rejected before root runs `rustdesk-provision-finalize --confirm-remote-auth`.
5. Validate Wayland, TCC, Aqua/LoginWindow, sleep, and FileVault behavior.
6. After any reservation exists, failure means RustDesk stopped plus fixed-forward to a fresh revision; never activate an older generation.
7. The accepted transient password argv and possible non-core crash-metadata exposure remain in force.
