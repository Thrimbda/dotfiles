# Aliyun Acorn HTTPS Firewall Ports - Task List

## Quick Resume

**Current Phase**: Delivery
**Current Checkpoint**: Review passed and evidence recorded
**Progress**: 4/5 phases complete

---

## Phase 1: Contract COMPLETE

- [x] Capture user correction that public `443` is required.
- [x] Capture user correction that firewall ports `2223` and `2224` are required.

---

## Phase 2: Worktree Envelope COMPLETE

- [x] Create isolated worktree and branch from `origin/master`.

---

## Phase 3: Implementation COMPLETE

- [x] Restore HTTPS-only nginx staging for Vaultwarden/status without ACME.
- [x] Add firewall TCP `443`, `2223`, and `2224` while keeping `80` closed.

---

## Phase 4: Verification COMPLETE

- [x] Run Nix eval checks for ports, vhosts, ACME/Docker units, and Docker disabled state.
- [x] Run toplevel build.
- [x] Inspect generated nginx config and preStart.
- [x] Record test report and review.

---

## Phase 5: Delivery IN PROGRESS

- [x] Generate walkthrough and PR body.
- [x] Update wiki decisions and task summaries.
- [ ] PR lifecycle.

---

## Discovered Follow-ups

- Restore ACME/real certificates after DNS/cutover is ready.
