# Review Change: Gatus Axiom Cloudflare Access

> **Status**: BLOCKED  
> **Reviewed**: 2026-05-17  
> **Source**: repo diff plus `.legion/tasks/gatus-axiom-cloudflare-access/docs/test-report.md`

## Blocking Findings

1. **Cloudflare Access/DNS acceptance remains incomplete due credential permissions**
   - Evidence: `docs/test-report.md` records that the canonical encrypted Cloudflare API token can read DNS but receives `403` from Zero Trust Access endpoints; the user-authorized `/home/c1/dotfiles/token.env` file is absent; non-interactive host-key decryption for `axiom` cloudflared credentials is unavailable.
   - Impact: No Access app/policy was created or verified, and no `status-axiom.0xc1.space` DNS/tunnel route was created. The protected public route is therefore not live and the full task is not production-complete.
   - Minimal unblock: provide an Access-capable Cloudflare token, create/verify the exact-email Google Access app/policy first, then create the proxied CNAME route.

## Scope Review

- PASS: `hosts/axiom/default.nix` enables Gatus on `axiom`, keeps loopback origin `127.0.0.1:8080`, preserves `opencode-axiom.0xc1.space`, and adds `status-axiom.0xc1.space` cloudflared ingress before the 404 catch-all.
- PASS: `hosts/acorn/default.nix` no longer imports the old status module, and `hosts/acorn/modules/status.nix` is deleted, removing the repo-managed `status.0xc1.space` nginx public route.
- PASS: `docs/gatus-status.md` now describes the axiom/cloudflared/Cloudflare Access deployment shape.
- PASS: local Nix build/eval and `git diff --check` passed per `docs/test-report.md`.

## Security Lens

- Applied because this changes a public hostname and Cloudflare Access authentication boundary.
- No broad Access allow, bypass policy, non-Google IdP, token material, or cloudflared credential JSON was introduced into the repo.
- The decision not to create DNS before Access verification is correct and avoids an unauthenticated public surface after deployment.

## Decision

BLOCKED for full delivery. Repo-side implementation is reviewable, but live Cloudflare Access/DNS reconciliation remains blocked on an Access-capable credential.
