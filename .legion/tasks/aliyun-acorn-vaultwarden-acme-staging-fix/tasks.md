# Aliyun Acorn Vaultwarden ACME Staging Fix - Task List

## Quick Resume

**Current Phase**: Delivery
**Current Checkpoint**: Wiki writeback complete
**Progress**: 5/5 phases started

---

## Phase 1: Contract COMPLETE

- [x] Diagnose likely rebuild hang source | Acceptance: evaluated units show new `vault.0xc1.space` ACME units are pulled into nginx activation.
- [x] Define minimal safe staging fix | Acceptance: keep Vaultwarden service/secret, remove automatic Vaultwarden ACME/SSL until cutover.

---

## Phase 2: Worktree Envelope COMPLETE

- [x] Enter `git-worktree-pr` envelope | Acceptance: production config changes happen outside the shared main checkout.

---

## Phase 3: Diagnosis IN PROGRESS

- [x] Inspect live host logs | Acceptance: current generation, failed units, ACME logs, nginx status, and vaultwarden unit presence are known.
- [x] Confirm build/download/evaluation vs activation hang | Acceptance: remote build path or other evidence identifies where `nixos-rebuild switch` stalls.

---

## Phase 3b: Implementation COMPLETE

- [x] Apply minimal confirmed fix | Acceptance: fix addresses the live hang source, not only a local hypothesis.

---

## Phase 4: Verification COMPLETE

- [x] Run Nix eval/build and systemd unit checks | Acceptance: `aliyun-acorn` toplevel builds, Vaultwarden service remains enabled, and `nginx.service` no longer wants `acme-vault.0xc1.space.service`.
- [x] Record verification report | Acceptance: command evidence and residual risks are captured in task docs.

---

## Phase 5: Delivery PENDING

- [x] Run readiness review | Acceptance: review passes or blocker is recorded.
- [x] Generate walkthrough and PR body | Acceptance: reviewer-facing delivery summary exists.
- [x] Wiki writeback | Acceptance: task summary and durable decisions/follow-ups are updated.
- [ ] PR lifecycle | Acceptance: PR reaches terminal state or blocker is recorded.

---

## Discovered Follow-ups

- `status-axiom.0xc1.wang` ACME is failing with Let's Encrypt DNS NXDOMAIN. It failed quickly in observed logs, so it is not proven to be the rebuild hang, but the DNS/ACME mismatch should be corrected or explicitly disabled until the record exists.
- Re-enable TLS/ACME for `status-axiom.0xc1.wang` and `vault.0xc1.space` only after DNS points to `aliyun-acorn` and HTTP-01 validation is confirmed.
