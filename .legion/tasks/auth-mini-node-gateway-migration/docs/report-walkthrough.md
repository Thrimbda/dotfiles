# Delivery Walkthrough

**Mode:** `implementation`
**Status:** Verification and readiness review passed with no blocking findings. **No live deployment was performed.**

## What changed

- Pinned `auth-mini-gateway` to revision `28a4a273ea9b2725191dce35233f55972beaac6f` with verified Nix hashes.
- Added minimal, host-local Axiom gateways for Gatus and OpenCode on `127.0.0.1:7779/7780`; FRP now targets those gateways instead of the application ports.
- Kept Acorn as the TLS and auth-mini authority, removed only its status/OpenCode gateway instances, and routed those vhosts to FRP ports `18080/18081` with cookie, WebSocket, upload, and streaming behavior preserved.
- Added an Axiom-only encrypted environment secret, separate gateway state, and restrictive service settings. Internal application, gateway, and FRP ports remain absent from host firewalls.

## Delivery evidence

- Package build: PASS.
- Axiom toplevel build without activation: PASS.
- Targeted Acorn/Axiom topology, firewall, secret-metadata, and service-hardening evaluation: PASS.
- `git diff --check`: PASS.
- Scoped readiness review: PASS; no blocking findings or public auth bypass identified.

## Reviewer notes

- `TRUSTED_PROXY_CIDRS` is intentionally empty, so application-visible client IP is the loopback FRP peer rather than the original client.
- Cutover creates fresh gateway databases and a new cookie secret; existing status/OpenCode gateway sessions will reset.
- No Acorn closure build, activation, runtime cutover test, or live deployment was performed.

Evidence: [`implementation-note.md`](implementation-note.md), [`test-report.md`](test-report.md), and [`review-change.md`](review-change.md).
