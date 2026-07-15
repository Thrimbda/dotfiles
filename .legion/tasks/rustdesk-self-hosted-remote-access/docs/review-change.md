# Review Change: RustDesk rollout

## Current authoritative review — Charlie user-server runtime fixed-forward

### Findings

#### Blocking findings

None.

#### Non-blocking findings

1. **LOW — Exact recovery control flow has not yet run end-to-end as part of a candidate activation.** The verifier exercised the exact generated `postActivation` with syntax, lint, ordering and structural assertions, while the supplied target observation proves that the same manual `bootstrap` repaired the missing user job (`docs/test-report.md:28-44,91-105`). It did not switch or activate the candidate. This is an honest deployment evidence boundary rather than a pre-merge defect: both the no-GUI skip and active-GUI recovery branch must be observed during the first clean merged Charlie switch, before runtime/finalization is called PASS.
2. **LOW — The `print` then `bootstrap` recovery has a narrow concurrent-load race.** Sequential runs are idempotent: an existing job is not bootstrapped again, `kickstart` without `-k` does not replace a running instance, and an absent GUI domain is a successful no-op (`hosts/charlie/default.nix:1697-1716`). If another actor loads the same label after the negative `print` but before `bootstrap`, `bootstrap` can fail even though the job has appeared, making activation fail closed. This does not expose a secret, execute as root, or permit false readiness. If the race is ever observed, the minimal hardening is to accept a failed `bootstrap` only after an immediate `launchctl print` confirms the exact label now exists; it does not need to block this PR.

### Verdict

**PASS — ready for the Charlie runtime-fix PR and, after required checks and merge, entry into the Charlie deployment phase from a clean merged `origin/master`; not a runtime-auth or manual-finalization PASS.** No blocking correctness, security, scope, regression or verification finding was found. The current dirty feature worktree is not an authorized deployment source.

> **Review target**: `origin/master` / HEAD `2de54e09ed907defb3b116dea7c9d29429a40c41` plus the current uncommitted `hosts/charlie/default.nix` and verification-report diff
> **Direct author**: `engineer-swift-marten`
> **Verifier**: `verify-change-swift-ferret`
> **Verification gate**: current `docs/test-report.md` PASS for exact generated artifacts, full remote `aarch64-darwin` build and signed store bundle; candidate activation/runtime NOT RUN
> **Security lens**: applied — root activation, user-domain plist loading, IPC metadata, runtime secret boundary, revision/state reuse, operation lock and one-attempt/manual-finalize state machine
> **RFC disposition**: the user explicitly bypassed the stale “Charlie unchanged” amendment and required continuation without another RFC; that process lag is not a review blocker and this review does not modify `docs/rfc.md`
> **Reviewed**: 2026-07-14

### Review results

1. **Scope, minimality and explicit process bypass — PASS.** Before this review artifact, the only production path is `hosts/charlie/default.nix` at `+30/-9`; the other changed path is verifier-owned `docs/test-report.md`. There is no Acorn, Axiom, module, package, or `*.age` delta. The production changes are limited to the two duplicated validator expectations, one revision marker and a 21-line active-GUI recovery block. Charlie remains inside `plan.md:51-57`; the older Axiom-only RFC text is explicitly bypassed by the user's current rollout decision rather than silently treated as aligned.
2. **`501:0` metadata correction and `wheel_gid=0` — PASS.** The supplied target evidence records `/tmp/RustDesk-501`, `ipc` and `ipc.pid` as `501:0`, and records that the v7 primary-GID expectation failed before reservation while manual job bootstrap restored IPC (`docs/test-report.md:91-99`). The candidate derives UID with `id -u c1` but requires numeric group 0 for all three objects (`hosts/charlie/default.nix:758-778,1374-1391`). On supported macOS, wheel is the built-in GID 0; using the numeric kernel identity is appropriate for `stat -f %g` and matches the observed target. A platform drift would reject readiness before secret access rather than broaden acceptance.
3. **Symlink, type, owner and mode resistance — PASS.** Both provision and finalizer still require a non-symlink directory at exact `<uid>:0:0700`, a non-symlink socket at exact `<uid>:0:0600`, and a non-symlink regular PID file at exact `<uid>:0:0600`. The diff adds no `chmod`, `chown`, repair, fallback group, wildcard owner, or user-controlled path. PID bytes, launchd top-level job shape, PID equality, process UID/command/executable, `lsof` executable/socket binding, and stable start identity remain intact (`hosts/charlie/default.nix:779-819,1392-1428`). Changing primary GID to exact 0 therefore narrows the accepted real shape and does not weaken the existing fail-closed checks. Existing user-owned-directory race residuals remain inside the approved single-owner endpoint boundary and are not expanded by this diff.
4. **LaunchAgent recovery ordering, trust and no-GUI behavior — PASS with the LOW race above.** Independent evaluation of the exact candidate activation shows the managed app transaction first, then the generated launchd phase compares the candidate store plist, removes a destination symlink if present, copies `/Library/LaunchAgents/com.carriez.RustDesk_server.plist`, and invokes the existing load path; only later does `postActivation` pass the current-boot agenix revision gate and run the new recovery. Thus the fixed path is populated from the evaluated candidate before the fallback bootstrap. The bootstrap target is `gui/<c1 uid>`, so the agent executes in c1's user domain, not as root; it does not enlarge the privileged LaunchDaemon or root executable trust boundary. A pre-existing same-label user job can at worst cause fail-closed readiness/availability under the declared trusted-c1 model: provision still requires the exact signed RustDesk path, arguments, UID, PID, socket and executable before reaching the secret. If `gui/<uid>` does not exist, the outer probe skips bootstrap and kickstart without an error, preserving headless/login-window activation and leaving provision retries pre-reservation.
5. **Idempotence and process preservation — PASS.** Re-running activation with a loaded label takes only the non-destructive `kickstart` path; the absence of `-k` is intentional because activation must ensure demand, not invalidate a running server identity. A missing label is bootstrapped once and then kicked. Failures are surfaced rather than hidden, while an absent GUI domain is the only deliberate no-op. This avoids an activation-driven server replacement racing the provision state machine; the later provision helper remains the sole code that uses `kickstart -k` after password ACK and requires both service and server PID replacement (`hosts/charlie/default.nix:1096-1111`).
6. **Fresh revision and old-state non-reuse — PASS.** `provision=charlie-rustdesk-provision-v7` becomes `v8` inside the composite hash while `charlie-rustdesk-provision-v4:` remains the parser prefix (`hosts/charlie/default.nix:309-318`). Exact evaluated values change from `1dd4…26ee0` to `651a…be26`, so v7 stamp/reservation/ready values cannot compare current, but remain syntactically legal stale objects (`docs/test-report.md:46-60`). Both service and user-agent plists carry the new composite value and the provision derivation itself changes. Provision may replace only legal stale state under the existing ordering; finalizer requires current v8 reservation, ready and live identities and therefore cannot finalize v7 state. Malformed type, metadata or content still fails closed.
7. **Root activation, secret boundary and state machine — PASS.** The recovery block contains no secret path, config read, password argument, state deletion or finalizer call. It runs after the agenix current-revision/current-boot gate, while the provision daemon independently rechecks that gate before reservation, before secret resolution and before password invocation (`hosts/charlie/default.nix:966-1074,1681-1716`). Merely making the c1 agent available cannot bypass public-config, signed-app, privileged-service, user-process, IPC or identity gates. Provision and finalizer continue sharing the root-owned empty-directory operation lock; current reservation still means `attempt-used`; reservation is atomically published and synced before the secret is read; ready is published only after ACK, double PID replacement and public proof; finalizer remains zero-secret and requires explicit confirmation plus current live identities (`hosts/charlie/default.nix:463-545,975-1135,1177-1254,1477-1508`). The accepted short-lived password argv/crash-metadata residual is unchanged.
8. **Generated artifacts, remote Darwin build and deployability — PASS for PR/deployment entry.** Verification used the evaluated provision, finalizer, `postActivation` and full activation rather than source-only snippets; all four passed `bash -n`, focused scripts had zero ShellCheck findings, and full-activation diagnostics introduced no candidate finding. Differential assertions prove that each validator changed only the GID expectation and that recovery follows agenix gate → UID → GUI probe → job probe/bootstrap → kickstart. The exact dirty-source system derivation was fully realized in Charlie's remote store as `/nix/store/3yl4galgkg4xzpkn7nlsl7v9awjnpq46-darwin-system-25.11.ebec37a`; its sole RustDesk 1.4.9 bundle passed arm64, bundle/version, deep/strict codesign, Team ID and Gatekeeper notarization checks on Darwin (`docs/test-report.md:28-89`). This is sufficient to merge and then attempt a controlled deployment. It does not substitute for candidate activation, destination-app verification, launchd runtime, TCC, remote-auth controls or manual finalization.

### Security assessment

The security lens found no exploitable trust-boundary expansion. Root activation uses fixed absolute tools and a fixed system-managed plist path, and bootstraps only c1's GUI domain. Exact generated ordering places the evaluated plist before recovery; the loaded process remains UID c1 and must later satisfy signed-path, launchd, PID, executable and socket checks. The metadata change accepts the one observed platform shape but retains stricter-than-primary-group numeric ownership and exact modes. No secret source, decryption path, plaintext, ingress, root LaunchDaemon program, app payload, TCC grant, operation-lock rule, attempt rule or finalizer rule changes. Under the task's explicit single-owner trusted-endpoint model, a c1-controlled same-label collision is an availability/readiness failure, not a root privilege or secret bypass.

### Residual clean-merge deployment gates

1. Create the PR, run required checks, merge, and refresh a clean `origin/master`; never switch Charlie from this dirty worktree or a detached verification tree.
2. Before switch, reconfirm only approved state metadata: v7 has no current stamp/attempt/ready. Do not read the secret or RustDesk mutable config, run an old finalizer, reset state, or activate an older generation.
3. During switch, retain the generated ordering proof: verified destination app and candidate plist precede recovery. If no `gui/501` domain exists, activation must still succeed and no reservation may appear until valid runtime exists. If it exists, prove the exact user job, UID 501 process, `501:0` directory/socket/PID metadata, exact executable/arguments and stable IPC.
4. Prove exactly one v8 attempt, a current reservation plus current ready and no stamp; prove both auth-serving PIDs were replaced after ACK and that the operation lock is absent after successful provision. Any pre-reservation readiness failure remains retryable; any current reservation without valid ready is consumed and requires stop plus a fresh fixed-forward revision.
5. Verify `/Applications/RustDesk.app` destination signature/Team/Gatekeeper, public host/key/options, TCC Screen Recording/Accessibility/Input Monitoring, actual screen and keyboard/pointer control, and the preserved SSH/reverse-SSH/ToDesk fallback.
6. From a fresh controller, pass the new-password positive test and wrong/old/cross-host negative tests. Only then run the exact manual finalizer and prove current stamp, ready removal, fast-skip and no second password invocation.
7. On any post-reservation failure, stop the RustDesk jobs, do not finalize/reset/roll back, and fixed-forward with another fresh revision. Record runtime evidence in the follow-up evidence PR without secret or mutable-config contents.

### Review evidence and boundaries

- Independently inspected the complete production diff, `git status`, scope, `git diff --check`, plan, current test report, existing review/RFC history, both validator copies, launchd plists, activation ordering, revision inputs, provision/finalizer lock and state transitions.
- Independently evaluated the exact dirty candidate's full activation text and confirmed managed-app activation precedes generated plist copy/load, which precedes agenix-gated recovery. No activation output was executed.
- Treated `501:0`, manual-bootstrap success and v7 no-state facts as explicitly labeled orchestrator-supplied runtime evidence, not as this reviewer's independent observation.
- Did not read secret plaintext/ciphertext contents or RustDesk mutable config; did not modify production code or RFC; did not commit, push, deploy, switch, start/stop a service, run a finalizer, or alter remote state.

### 会话注意力摘要

- **Attention state**：OPEN for PR/deployment runtime evidence, **not** for RFC/design. It does not block this `review-change` PASS or PR creation.
- **已明确处置**：用户已显式要求继续 Charlie rollout 并 bypass 旧 RFC 的“Charlie不变”；不得再以该流程滞后要求新 RFC，也不得把旧文字冒充当前设计授权。
- **本轮已关闭**：`501:0` validator correctness、wheel GID 0、symlink/type/owner/mode防线、active-GUI recovery的顺序/幂等/信任边界、v8 stale-state隔离、root secret/lock/attempt边界，以及pre-merge build/signature证据充分性。
- **仍需关闭**：required checks/merge、clean merged switch、exact recovery branch、v8 one-attempt/ready、destination signature、TCC、真实远程认证正负测与manual finalize。
- **禁止动作**：从当前worktree直接switch、把build PASS写成runtime PASS、读取secret或mutable config内容、在外部认证前finalize、reset已消耗revision、或rollback到旧generation。

---

## Historical Axiom fixed-forward review — findings

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

---

## Current Axiom PID-stability follow-up — 2026-07-13

### Findings

- **Blocking:** None.
- The 30-second dwell snapshots and then revalidates both main/server PID plus start identity in each pre-password and post-restart `wait_runtime`; it rejects the observed approximately 27-second server replacement while retaining every later fail-closed PID check.
- A normal successful provision adds 56 seconds over the two former 2-second dwells. Under repeated near-ready churn, `TimeoutStartSec=8min` is the effective cap rather than all 60 full dwells; that bounded timeout remains state-safe (pre-reservation failure is retryable, post-reservation failure remains fixed-forward only).
- The v8 marker and serialized dwell value produce `axiom-rustdesk-provision-v4:cdaeca40df2b16a3bc07e4614411fce472e892db744d987fc495995c270ab62c`; the unchanged v4 prefix keeps prior reservation/ready objects legal stale state. Scope is one Axiom production file, with no secret, trust-boundary, privilege, ingress, or finalizer change. Security lens applied.

### Verdict

**PASS — ready for the Axiom-only PID-stability hotfix PR, not for deployment or finalization.** The supplied generated-script, ShellCheck, isolated-state, and full-build evidence (`/nix/store/vrmh1rbjrn3lgw05gp4ldcz1rrzk2zx6-nixos-system-axiom-25.11.20260630.b6018f8`) is sufficient for this minimal diff; live readiness and remote-auth gates remain outstanding.
