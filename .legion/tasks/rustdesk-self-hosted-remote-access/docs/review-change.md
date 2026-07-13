# Review Change: RustDesk Axiom fixed-forward hotfix

## Findings

### Blocking findings

None.

### Non-blocking findings

1. **LOW — Some task status text still points at the superseded Round 8 gate.** `docs/rfc.md:4,391-414`, `docs/research.md:6,218,238`, and `tasks.md:5-7` still say that a fresh RFC review is pending or that Round 8 FAIL is current, although `docs/review-rfc.md:1-21` records the current Round 9 design PASS. In addition, `docs/research.md:50-54` calls the root-preserving combination a “proven conjunction,” while `docs/review-rfc.md:13-15,25` correctly says that exact combination remains a deployment hypothesis. This is conservative or locally imprecise rather than an unsafe rollout claim: the authoritative test report (`docs/test-report.md:3-12,111-123`) and this review explicitly leave candidate runtime unproved. Update those status/index sentences before or with the PR so future operators do not have to infer precedence.
2. **LOW — The exact NixOS switch transition was reasoned from pinned implementation and current unit state, not executed as a candidate lifecycle test.** The report exercises generated units and the provision state machine (`docs/test-report.md:24-40`) but does not emulate `rustdesk.service=inactive` plus `rustdesk-provision.service=active/exited`. Read-only review confirmed those current states and an active `multi-user.target`; the locked NixOS switcher stops and starts an active changed service, and the changed provision unit pulls the main service through `Wants=`/`After=` (`hosts/axiom/default.nix:1569-1584`). This leaves no realistic pre-merge skip/double-run defect, but the actual switch output, unit invocation count, and one-attempt state must be captured in the post-merge runtime evidence.

## Verdict

**PASS — ready for the Axiom-only hotfix PR, not for deployment or finalization.** No blocking correctness, security, regression, scope, or verification finding was found.

> **Review target**: `origin/master` / HEAD `0026eb9922c87e9624ed7352b09b58cddb1a45a3` plus the current uncommitted hotfix/documentation diff
> **Design gate**: Round 9 `PASS — design only`
> **Verification gate**: current `docs/test-report.md` static/generated/state/full-build PASS; candidate runtime NOT RUN
> **Security lens**: applied — root service/session coupling, immutable plugin loading, secret use, revision/state transition, finalizer identity, and fixed-forward/rollback boundaries
> **Reviewed**: 2026-07-13

## Review results

1. **Resolver direction, scope, and canonical config — PASS.** `networking.hosts.${acornPublicIp} = [ rustdeskHost ];` is the correct IP-to-hostnames direction (`hosts/axiom/default.nix:1501-1504`), and the generated hosts file is `8.159.128.125 rustdesk.0xc1.wang`. The public configuration still writes and proves `rustdesk.0xc1.wang` for both host and relay (`hosts/axiom/default.nix:231-266,821-843`); the public IP is only the Axiom NSS target. No client ingress, Acorn, or Charlie resolver change is present.
2. **Root storage and child environment boundary — PASS with runtime gate.** The root unit retains `HOME=/root` and `XDG_CONFIG_HOME=/root/.config`, declares no `XDG_DATA_HOME`, and keeps the generated immutable-store `PATH` rather than adding `/run/current-system/sw` (`hosts/axiom/default.nix:166-178,1543-1566`). The password CLI separately remains in `/root` and `/root/.config` (`hosts/axiom/default.nix:304-313,614-632,954-960`). No production addition copies, moves, removes, chowns, or points root RustDesk storage at c1 state. Upstream may override or conditionally preserve values while spawning c1 through `sudo`; therefore the unit text is not treated as child proof. The required live child allowlist check remains explicit in `docs/test-report.md:117-123`.
3. **Wrapper composition and PipeWire closure — PASS.** The RustDesk wrapper prefixes GStreamer core and `gst-plugins-base`; the unit-provided immutable `${pkgs.pipewire}/lib/gstreamer-1.0` is consequently appended, not substituted for those paths (`hosts/axiom/default.nix:175,1554`). The exact unit directly references the PipeWire store output, `libgstpipewire.so` exists in that output, the toplevel closure retains it, and exact-path `gst-inspect-1.0` resolves `pipewiresrc`, `videoconvert`, and `appsink` (`docs/test-report.md:34-39,70-90`). Child receipt of the composed value remains a runtime gate.
4. **Composite revision and stale-state legality — PASS.** The hash adds a fixed runtime-contract marker, the canonical resolver tuple, and deterministic `builtins.toJSON` serialization of the shared eleven-value environment (`hosts/axiom/default.nix:287-303`). Those inputs contain only public constants and immutable store paths; the existing secret input remains a ciphertext store-path identity, not plaintext. The digest changes from `bea8…10a` to `bf93…9b8`, while `axiom-rustdesk-provision-v4:` remains unchanged, so the deployed reservation/ready parse as legal stale objects rather than malformed state (`docs/test-report.md:63-68`).
5. **Stale reservation/ready ordering and finalizer rejection — PASS.** Provision proves runtime/public state, publishes and syncs the new reservation, removes and syncs stale ready, revalidates runtime, and only then resolves/reads the secret and calls `--password` (`hosts/axiom/default.nix:859-960`). The candidate finalizer requires a current reservation and current ready before checking live identities and publishing a stamp (`hosts/axiom/default.nix:1356-1386`), so old state cannot finalize. Exact generated-script differential checks show no state-machine logic change beyond revision identity, and the isolated transition test proves stale replacement, one-attempt behavior, and old-state finalizer rejection (`docs/test-report.md:36-38,80-90`).
6. **Activation/restart behavior — PASS with bounded operational residual.** The currently active/exited `RemainAfterExit` provision unit changes both `ExecStart` and `X-Restart-Triggers`; locked NixOS switch semantics therefore stop it before activation and start it after daemon reload. Its start transaction pulls the currently stopped main service through `Wants=rustdesk.service` and orders provision after it. The active `multi-user.target` also re-evaluates wanted dependencies. Concurrent requests are coalesced by systemd, and `RemainAfterExit` makes a later start a no-op. Under normal process-interruption and orderly-reboot semantics, a repeated switch cannot cause a second password call after reservation publication because the operation lock and current-reservation branch fail closed. Sudden storage/controller uncertainty remains a stop-and-fixed-forward condition. Other realistic failures are missing session/runtime readiness or a failed dependency; these either leave RustDesk stopped or fail before reservation, and still require runtime observation rather than a success claim.
7. **Scope and documentation claims — PASS.** Before this review artifact, the diff contains six task-local documents and only one production file, `hosts/axiom/default.nix`. There is zero diff under `hosts/acorn/**`, `hosts/charlie/**`, `modules/**`, `packages/**`, or any `*.age` file. Charlie remains explicitly blocked until Axiom manual finalize (`docs/test-report.md:111-123`). The current authoritative report repeatedly says no candidate switch, start, authentication, capture/input, secret read, or finalization occurred; aside from the LOW wording drift above, it does not claim candidate runtime success.
8. **Verification sufficiency — PASS for pre-merge claims.** Exact option evaluation, generated hosts/unit/scripts, wrapper/closure/factory execution, base/candidate revision comparison, isolated stale-state transitions, and a fresh full Axiom toplevel build directly cover the implementation claims (`docs/test-report.md:22-109`). Historical unchanged package/public-IPC/state-machine evidence remains applicable because generated provision/finalizer logic is byte-equal after normalizing only revision identity. Runtime-dependent child inheritance, NSS/NAT behavior, mutable-state ownership, graphics, authentication, and finalization are clearly excluded from the PASS.

## Security assessment

The hotfix adds no secret source, decryption path, password call, privilege transition, public port, or mutable migration. Session bus/runtime coordinates intentionally couple the root service to the trusted c1 graphical session, but they do not authorize c1 persistent storage and remain within the approved single-owner endpoint boundary. The only new plugin directory is an immutable Nix store path. Existing transient password-argv/crash-metadata residuals are unchanged. No exploitable trust-boundary expansion or secret leakage was found.

## Residual post-merge runtime gates

1. Merge/checks first; use a clean merged `origin/master` descendant of `0026eb99`, with RustDesk still stopped.
2. Reconfirm old reservation/ready are legal stale/identity-invalid, with no stamp; do not resume, reset, run an old finalizer, or roll back a generation.
3. During switch, observe the changed provision unit run once and pull the candidate main unit; prove one new-revision password attempt, fresh current reservation + ready, no stamp, and stable fresh process identities.
4. Compare only approved root/c1 path metadata before and after; require root canonical state to remain `root:root` and no c1 ownership migration.
5. Read only the approved root and c1 child environment keys. Prove actual child values and the composed core/base/PipeWire path; do not infer inheritance from the parent unit.
6. Prove canonical NSS resolution to `8.159.128.125`, exclusion of Clash fake-IP, and UDP 21116/TCP 21115 NAT behavior while public config remains canonical.
7. Post-ready only, prove the actual Wayland socket, c1 bus, portal, PipeWire stream/node, GStreamer factories, screen capture, and keyboard/pointer control.
8. Run correct-password positive and wrong/old/cross-host negative controls from a fresh controller; only then run the exact manual finalizer and prove stamp/fast-skip/no-second-attempt.
9. Any post-ready failure consumes the revision: stop RustDesk, do not finalize/reset/rollback, and fixed-forward again. Charlie remains blocked until Axiom finalizes successfully.

## Review evidence and boundaries

- `git diff --check origin/master`: **PASS**.
- Read-only current-state inspection confirmed Axiom main `inactive/dead`, provision `active/exited`, and `multi-user.target` active; no unit was started, stopped, restarted, or changed.
- No secret plaintext/ciphertext content or RustDesk public-key value was read or recorded. No production code, service state, finalizer state, deployment, commit, push, or PR was changed by this review.

---

## Historical configuration-PR review — preserved, superseded for the current hotfix

The review below applies to the original configuration PR ending at `3db55d1c`. It remains historical evidence and is not approval of the Axiom fixed-forward candidate or its runtime behavior.

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
