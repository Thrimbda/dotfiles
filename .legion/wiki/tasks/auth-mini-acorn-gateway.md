# Auth Mini Gateway on Acorn

## Metadata

- `task-id`: `auth-mini-acorn-gateway`
- `status`: `ready for PR`
- `risk`: `medium`
- `schema-version`: `current`
- `historical`: `false`
- `supersedes`: `nginx Basic Auth boundary for Acorn status/opencode/frps dashboard 0xc1.wang routes`
- `superseded-by`: `(none)`

## Outcome Summary

This task deploys `auth-mini` and `auth-mini-gateway` on the canonical `acorn` host. `auth-mini` is published at `auth.0xc1.wang`. `auth-mini-gateway` is published at `auth-gateway.0xc1.wang` and also runs origin-scoped instances for the protected `0xc1.wang` service hostnames.

The Acorn nginx routes `status-axiom.0xc1.wang`, `opencode-axiom.0xc1.wang`, and `frps-acorn.0xc1.wang` now use nginx `auth_request` against local gateway instances instead of nginx Basic Auth. Vaultwarden remains unchanged because it has native clients and app-level authentication.

## Reusable Decisions

- Current upstream `auth-mini-gateway` is same-origin by design: `GATEWAY_PUBLIC_BASE_URL` gates return targets and cookies are host-only. Use one gateway instance per protected hostname unless upstream adds explicit multi-origin/cookie-domain support.
- Keep `auth-mini` and gateway backend listeners loopback-only. Public traffic enters only through nginx-managed HTTPS vhosts.
- Store gateway cookie secret and allowlist in agenix. Do not put gateway secrets, auth-mini tokens, refresh tokens, or plaintext allowlist env files into Nix store outputs or task docs.
- Keep Vaultwarden out of the browser gateway unless a future Vaultwarden-specific compatibility design proves native clients still work.

## Validation

- `auth-mini` package build passed.
- `auth-mini-gateway` package build passed; upstream Rust tests passed `11 passed`.
- `acorn` toplevel build passed.
- Focused evals proved backend ports `7777`-`7781` are not firewall-opened, gateway env uses per-origin public base URLs, protected vhosts use `auth_request`, and Vaultwarden still proxies to its original local service.
- Generated nginx config inspection confirmed full public hostnames and per-origin gateway ports.

## Operational Follow-Up

- Create or verify DNS-only Cloudflare records for `auth.0xc1.wang` and `auth-gateway.0xc1.wang` pointing to Acorn.
- Deploy/switch Acorn and confirm `auth-mini.service` plus all `auth-mini-gateway-*` services are active.
- Confirm ACME issuance for the two new hostnames.
- Bootstrap auth-mini admin and configure issuer `https://auth.0xc1.wang` plus RP ID `auth.0xc1.wang`.
- Smoke unauthenticated redirects, allowlisted access, denied-user `403`, logout, and Opencode WebSocket behavior.

## Related Raw Sources

- `plan`: `.legion/tasks/auth-mini-acorn-gateway/plan.md`
- `log`: `.legion/tasks/auth-mini-acorn-gateway/log.md`
- `tasks`: `.legion/tasks/auth-mini-acorn-gateway/tasks.md`
- `rfc`: `.legion/tasks/auth-mini-acorn-gateway/docs/rfc.md`
- `rfc-review`: `.legion/tasks/auth-mini-acorn-gateway/docs/review-rfc.md`
- `test-report`: `.legion/tasks/auth-mini-acorn-gateway/docs/test-report.md`
- `change-review`: `.legion/tasks/auth-mini-acorn-gateway/docs/review-change.md`
- `walkthrough`: `.legion/tasks/auth-mini-acorn-gateway/docs/report-walkthrough.md`
- `pr-body`: `.legion/tasks/auth-mini-acorn-gateway/docs/pr-body.md`
