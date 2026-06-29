# Aliyun Acorn Vaultwarden Dual Run - Task List

## Quick Resume

**Current Phase**: Delivery
**Current Checkpoint**: Walkthrough and wiki writeback complete; PR lifecycle pending
**Progress**: 5/6 phases complete

---

## Phase 1: Contract COMPLETE

- [x] Confirm migration boundary | Acceptance: User selected dual-run, so `acorn` remains unchanged while `aliyun-acorn` gets its own deployment config.
- [x] Identify secret feasibility | Acceptance: Current local key matches `aliyunAcorn`, but cannot decrypt the existing `acorn` `vaultwarden-env.age`.
- [x] Finalize blocker decision | Acceptance: User provided `./acorn_id_ed25519`; its public key matches the old acorn recipient, and target `/home/c1/.ssh/id_ed25519` matches `aliyunAcorn`.

---

## Phase 2: Worktree Envelope COMPLETE

- [x] Enter `git-worktree-pr` envelope | Acceptance: Production config changes happen outside the shared main checkout.

---

## Phase 3: Implementation COMPLETE

- [x] Add `aliyun-acorn` Vaultwarden host config | Acceptance: service, nginx vhost, tmpfiles, and import match the approved dual-run scope.
- [x] Add valid `aliyun-acorn` Vaultwarden secret | Acceptance: `hosts/aliyun-acorn/secrets/vaultwarden-env.age` exists and is encrypted to the `aliyunAcorn` recipient without exposing plaintext.

---

## Phase 4: Verification COMPLETE

- [x] Run Nix build/eval checks | Acceptance: `aliyun-acorn` configuration evaluates/builds or blockers are recorded with exact failure scope.
- [x] Verify config shape | Acceptance: Vaultwarden service, nginx routes, secret ownership, and fail2ban integration are present on `aliyun-acorn` and `acorn` remains unchanged.

---

## Phase 5: Review COMPLETE

- [x] Review implementation | Acceptance: `docs/review-change.md` records pass/fail, secret-handling safety, and operational residual risks.

---

## Phase 6: Delivery PENDING

- [x] Produce walkthrough and PR body | Acceptance: reviewer-facing summary and test evidence are available.
- [x] Update Legion wiki | Acceptance: task summary and reusable secret-migration decisions are written back.
- [ ] Complete PR lifecycle or record blocker | Acceptance: PR is merged/closed/blocked with worktree cleanup status documented.

---

## Discovered Follow-ups

(None yet.)
