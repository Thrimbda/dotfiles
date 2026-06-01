# Review Change: Gatus Axiom Cloudflare Access

> **Status**: PASS
> **Reviewed**: 2026-06-01
> **Source**: repo diff plus `.legion/tasks/gatus-axiom-cloudflare-access/docs/test-report.md`

## Blocking Findings

None.

## Scope Review

- PASS: `hosts/axiom/default.nix` enables Gatus on `axiom`, keeps loopback origin `127.0.0.1:8080`, preserves `opencode-axiom.0xc1.space`, and adds `status-axiom.0xc1.space` cloudflared ingress before the 404 catch-all.
- PASS: `hosts/acorn/default.nix` no longer imports the old status module, and `hosts/acorn/modules/status.nix` is deleted, removing the repo-managed `status.0xc1.space` nginx public route.
- PASS: `docs/gatus-status.md` describes the axiom/cloudflared/Cloudflare Access deployment shape.
- PASS: local Nix build/eval and `git diff --check` passed per `docs/test-report.md`.
- PASS: Cloudflare Access and DNS are reconciled for `status-axiom.0xc1.space` per `docs/test-report.md`.

## Security Lens

- Applied because this changes a public hostname and Cloudflare Access authentication boundary.
- The Access app is self-hosted, restricted to the Google IdP, and auto-redirects to identity.
- The allow policy uses exact emails `c1@ntnl.io`, `siyuan.arc@gmail.com`, and `froggy2818@gmail.com`, requires Google login, and has no broad domain/everyone/group/service-token/bypass policy.
- DNS was created only after Access assertions passed.
- No plaintext API token, tunnel credential JSON, `TunnelSecret`, or OIDC secret was introduced into the repo.

## Residual Risks

- Production `axiom` deployment was intentionally not run in this task.
- Interactive browser allow/deny behavior remains a manual post-deploy smoke check.

## Decision

PASS. Repo-side implementation and Cloudflare Access/DNS reconciliation are ready; deployment and browser smoke checks remain manual.
