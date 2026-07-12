# RustDesk Self-Hosted Remote Access — Delivery Walkthrough

> **Mode:** `implementation`
> **Review decision:** configuration PR readiness only
> **Final review:** **PASS — ready for the configuration PR**
> **Deployment status:** **NOT RUN**

> [!IMPORTANT]
> **This PR has NOT deployed anything. It does not authorize a production switch until it is merged and every host is refreshed to the same clean merged `origin/master` baseline.**

## Delivery Identity

| Item | Current evidence |
|---|---|
| Base | `origin/master` at `0d61c714` |
| Production commit | `3db55d1c` |
| Evidence review commit | `02e188b9`; later branch commits are reviewer-facing docs only |
| Design gate | Round 7 `review-rfc`: PASS for implementation |
| Change gate | Final `review-change`: PASS for the configuration PR |

The committed diff is host-local configuration, encrypted secret payloads/mappings, and Legion evidence. The evidence-only commit changes task records, not production configuration. Only the current 1.4.9 evidence is applicable; the historical 1.4.8 evidence in the source documents is explicitly superseded.

## What This PR Configures

| Host | Configuration delivered | Boundary that remains |
|---|---|---|
| **Acorn** | NixOS-native RustDesk Server 1.1.14 (`hbbs`/`hbbr`), a dedicated agenix-managed RustDesk identity key with fail-closed preflight, and host firewall ingress limited to TCP 21115–21117 plus UDP 21116. | DNS, Aliyun security-group rules, live listeners, registration, direct connection, and relay are post-merge gates. |
| **Axiom** | RustDesk client 1.4.9 built from pinned source, with the cargo vendor derivation rebuilt from that same source; a host-local systemd service; pinned public server configuration; and an independent agenix password secret. | Live systemd/process identity, Hyprland/Wayland, remote authentication, and finalization are post-merge gates. |
| **Charlie** | The official ARM64 RustDesk 1.4.9 app, preserved under its upstream signature/notarization boundary; transactional app installation; upstream-shaped service/server launchd jobs; and a separate provision job and password secret. | `/Applications/RustDesk.app` destination verification, live launchd jobs, TCC, Aqua/LoginWindow, remote authentication, and finalization are post-merge gates. |

The server identity is separate from SSH, and Axiom and Charlie use different host-scoped password secrets. No public-key value, ciphertext, fingerprint, password, or secret-derived value is reproduced in this handoff.

## Provisioning and Finalization Contract

Both clients implement the reviewed one-shot protocol:

1. Prove the main service, active-user process/IPC, and public configuration before reading the password secret.
2. Durably publish the current revision's **reservation** before secret access or the password call.
3. Permit one bounded upstream password invocation for that revision and require the exact success acknowledgement.
4. Replace both authentication-serving processes, re-prove public configuration and stable process identities, then publish **ready-to-finalize**. Provisioning never writes the success stamp.
5. From a fresh external controller, prove the **new password succeeds** and the **old, wrong, and other host's passwords are rejected**. A transport failure is not an authentication rejection.
6. Only then run the explicit manual finalizer. It revalidates reservation, ready state, and process identities under the shared lock; it reads no secret and invokes no password API before writing the stamp.

In short: **reservation → ready → external remote auth → manual finalize**.

> [!CAUTION]
> Once a reservation exists, failure or uncertainty must leave RustDesk stopped and **fixed-forward to a fresh revision**. Do not retry automatically and do not activate an older generation.

## Existing Verification Evidence

This walkthrough only reorganizes existing delivery evidence. No tests were rerun and no host was contacted while producing it.

| Evidence | Result | Source |
|---|---|---|
| Final Acorn full NixOS toplevel build | **PASS** | [`test-report.md` — Candidate and build evidence](./test-report.md#candidate-and-build-evidence) |
| Final Axiom full NixOS toplevel build; effective client 1.4.9 | **PASS** | [`test-report.md` — Candidate and build evidence](./test-report.md#candidate-and-build-evidence) |
| Final Charlie full `aarch64-darwin` system build from exact production commit `3db55d1c` | **PASS** | [`test-report.md` — Candidate and build evidence](./test-report.md#candidate-and-build-evidence) |
| Charlie ARM64 1.4.9 store app: deep/strict signature, expected official signer identity, and Gatekeeper notarization; an identical writable copy retained the same trust result | **PASS** | [`test-report.md` — Candidate and build evidence](./test-report.md#candidate-and-build-evidence) |
| Generated launchd parser on Charlie's `/usr/bin/awk`, using complete real service and user-agent output while excluding nested coalition `state` fields; PID/start identity format also checked | **PASS** | [`test-report.md` — Charlie target-platform evidence](./test-report.md#charlie-target-platform-evidence) |
| Generated provision/finalizer syntax and lint, state/failure matrices, IPC fallback controls, process replacement, and finalizer zero-secret assertions | **PASS** | [`test-report.md` — Generated helper and state evidence](./test-report.md#generated-helper-and-state-evidence) |
| Correctness, security, scope, and maintainability review | **PASS — no blocking finding** | [`review-change.md`](./review-change.md) |

The Charlie signature evidence above applies to the built store artifact and verified temporary copy. It is not evidence for the future live destination; destination signature and job state remain mandatory after merge.

## Security Boundary and Residuals

- The normal path keeps plaintext out of Git, Nix store content, generated units/plists, regular logs, and review evidence.
- Client finalizers contain no secret resolver, secret path, or password invocation.
- Client 1.4.9 is the security floor; 1.4.8 is not a deployment, fallback, or rollback target.
- Axiom and Charlie remain single-owner trusted endpoints. The approved residual is a brief password value in the upstream child process argv and a low-probability possibility of non-core crash metadata if that process fails in the same window.
- Per-service core limits reduce traditional core risk but do not prove that argv metadata cannot exist.
- Existing SSH, reverse-SSH, and ToDesk recovery paths remain in place.

## Required Post-Merge Gates — Do Not Skip

> [!WARNING]
> **Merge permits the rollout procedure to begin; it does not prove deployment. Use the strict order: Acorn → Axiom → Charlie. Stop at the first failed gate.**

1. **Clean merged baseline**
   - Merge the configuration PR, refresh to the resulting `origin/master`, and record the merged commit.
   - Confirm every deployment checkout is tracked-clean and at that same commit; never switch from the feature or Charlie verification worktree.
2. **DNS and security group**
   - Publicly resolve the DNS-only RustDesk name to Acorn.
   - Confirm Aliyun SG ownership and allow only TCP 21115–21117 plus UDP 21116; externally reject 21114/21118/21119 and retain a relay-cost/traffic owner.
3. **Acorn first**
   - Switch Acorn from the clean merged baseline.
   - Verify key preflight without printing key material, `hbbs`/`hbbr`, restart behavior, listeners, host firewall, SG, registration, direct access, and relay. Do not proceed on failure.
4. **Axiom second**
   - Switch the same baseline; verify client 1.4.9, systemd topology, main/user process replacement, IPC/public configuration, and active Hyprland/Wayland behavior.
   - After reservation and ready exist, run the fresh-controller new-password positive test and old/wrong/cross-host negative tests. Finalize only after all are genuine authentication results.
5. **Charlie third**
   - Build/switch the same baseline; verify the final `/Applications/RustDesk.app` signature, notarized identity, managed ownership, and service/server/provision launchd jobs before trusting provisioning.
   - Verify process replacement and public configuration, then repeat the new-password positive and old/wrong/cross-host negative tests before manual finalize.
6. **Platform and connection acceptance**
   - Complete Charlie Screen Recording, Accessibility, and Input Monitoring TCC grants.
   - Record Axiom Wayland and Charlie Aqua/LoginWindow behavior, plus lock/login/sleep and FileVault limits, direct/forced-relay behavior, and fallback-path availability without expanding capability claims.
7. **Evidence PR**
   - Submit a separate follow-up evidence PR tied to the merged deployment commit, recording only non-secret runtime PASS/FAIL evidence and any residual failures.

At both client stages, **no successful stamp may exist before the external positive and all required negative authentication checks pass**.

## Reviewer Checklist

- [ ] Acorn uses the dedicated RustDesk key boundary and only the approved native-client ports.
- [ ] Axiom's 1.4.9 source and cargo vendor derivation come from the same pinned source, and its provision dependency remains `Wants=` + `After=` only.
- [ ] Charlie preserves the official signed/notarized app and validates the final destination before loading trusted jobs.
- [ ] Reservation, process replacement, ready publication, external authentication, and manual finalization remain separate gates.
- [ ] Any post-reservation failure is fixed-forward, never generation rollback.
- [ ] The PR is reviewed as configuration only, with no claim that DNS, SG, switch, runtime auth, TCC, Wayland, or sleep validation has occurred.

## Evidence Index

- Contract: [`../plan.md`](../plan.md)
- Design: [`rfc.md`](./rfc.md)
- Design review: [`review-rfc.md`](./review-rfc.md)
- Verification: [`test-report.md`](./test-report.md)
- Final change review: [`review-change.md`](./review-change.md)
