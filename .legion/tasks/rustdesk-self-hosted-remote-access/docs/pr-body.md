## Summary

- Configure Acorn with NixOS-native RustDesk Server 1.1.14, a dedicated agenix-managed server key, fail-closed key preflight, and only TCP 21115–21117 plus UDP 21116.
- Configure Axiom with a source-built RustDesk 1.4.9 client whose cargo vendor derivation is rebuilt from the same pinned source, plus the host-local systemd service and independent password secret.
- Configure Charlie with the signed/notarized official ARM64 RustDesk 1.4.9 app, transactional destination handling, upstream-shaped launchd jobs, and its own password secret.
- Implement the reviewed one-shot **reservation → ready → external remote auth → manual finalize** protocol on both clients. Any failure after reservation requires RustDesk stopped plus fixed-forward to a fresh revision, never generation rollback.

## Deployment Boundary

> [!IMPORTANT]
> **This PR has NOT deployed anything and does not authorize a production switch until merge.** All hosts must switch from the same clean merged `origin/master` baseline, not this feature or verification worktree.

- Base: `origin/master` `0d61c714`
- Production commit: `3db55d1c`
- Evidence review commit: `02e188b9`; later branch commits are reviewer-facing docs only
- Final review: **PASS — ready for the configuration PR**

## Safety

- Server and per-client credentials remain separate host-scoped agenix secrets; this PR body contains no key value, ciphertext, fingerprint, password, or secret-derived value.
- Client 1.4.9 is the minimum allowed version; 1.4.8 is not an acceptable deploy, fallback, or rollback target.
- The approved single-owner residual remains: the upstream password command briefly carries the password in child-process argv, with a low-probability non-core crash-metadata risk.
- Existing SSH, reverse-SSH, and ToDesk recovery paths remain available.

## Validation

- Final Acorn and Axiom full NixOS toplevel builds: **PASS**; Axiom's effective client is 1.4.9.
- Final Charlie full `aarch64-darwin` system build from `3db55d1c`: **PASS**.
- Charlie's built ARM64 1.4.9 app passed deep/strict signature and expected signer checks; Gatekeeper accepted its notarization. An identical writable copy retained the same trust result. Live `/Applications` verification remains post-merge.
- Charlie's generated parser passed on target `/usr/bin/awk` against complete real service/user-agent `launchctl print` output while ignoring nested coalition states.
- Generated helpers, state/failure matrices, IPC fallback controls, process replacement, and zero-secret finalizer assertions: **PASS**.
- Final security/correctness review: **PASS**, no blocking finding.

Existing evidence: [`test-report.md`](.legion/tasks/rustdesk-self-hosted-remote-access/docs/test-report.md) and [`review-change.md`](.legion/tasks/rustdesk-self-hosted-remote-access/docs/review-change.md). No tests or host connections were performed to create this PR body.

## Required Post-Merge Rollout

1. **Baseline:** merge, refresh every deployment checkout to the same clean merged commit, and record it.
2. **DNS/SG:** verify public DNS; allow only TCP 21115–21117 and UDP 21116; reject 21114/21118/21119; confirm relay ownership.
3. **Acorn:** switch first; verify key preflight, services, listeners, firewall/SG, registration, direct access, and relay.
4. **Axiom:** switch second; verify 1.4.9, systemd/PID replacement, public config, and Wayland. Before finalize, require new-password success plus old/wrong/cross-host authentication rejection from a fresh controller.
5. **Charlie:** switch third; verify final destination signature and all launchd jobs before provisioning. Repeat the positive/negative remote-auth gate before finalize.
6. **Platform gates:** complete Charlie TCC; record Wayland, Aqua/LoginWindow, lock/login/sleep/FileVault, direct/relay, and fallback results.
7. **Evidence PR:** submit non-secret runtime PASS/FAIL evidence tied to the merged deployment commit.

> [!CAUTION]
> Do not finalize on a transport failure, do not advance to the next host after a failed gate, and fixed-forward after any published reservation.

## Review Focus

- Same-source Axiom source/cargo vendor binding and systemd dependency shape.
- Acorn key isolation and minimal ingress.
- Separation of reservation, ready state, external authentication, and zero-secret manual finalization.
- Charlie official-app trust boundary, destination gate, and launchd parser/job shape.

Walkthrough: [`report-walkthrough.md`](.legion/tasks/rustdesk-self-hosted-remote-access/docs/report-walkthrough.md)
