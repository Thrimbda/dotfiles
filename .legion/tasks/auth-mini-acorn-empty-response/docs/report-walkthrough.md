# Report Walkthrough

Mode: implementation.

## What Changed

- Added an exact nginx root route for `auth.0xc1.wang` that returns `302 /web/`.
- Left the existing auth-mini catch-all proxy unchanged for all non-root paths.
- Created the missing live Cloudflare DNS-only A records for `auth.0xc1.wang` and `auth-gateway.0xc1.wang` to `8.159.128.125` using the existing Cloudflare DNS token.

## Why

The reported browser error was `NS_ERROR_NET_EMPTY_RESPONSE` for `auth.0xc1.wang` after switching Acorn.

Live diagnostics showed Acorn's `auth-mini.service` was healthy and `GET /web/` worked when requests reached Acorn. The empty response came from missing Cloudflare DNS records: local DNS/proxy resolution produced `198.18.x.x` fake-ip addresses instead of Acorn.

After the DNS fix, the remaining repo-owned UX issue is that `auth.0xc1.wang/` maps to auth-mini's API root and returns JSON `404`; the actual UI is `/web/`. The nginx redirect makes the public root usable after the next switch.

## Files

- `hosts/acorn/modules/auth-mini.nix`: root `= /` redirect to `/web/` for `auth.0xc1.wang`.
- `.legion/tasks/auth-mini-acorn-empty-response/plan.md`: hotfix contract.
- `.legion/tasks/auth-mini-acorn-empty-response/docs/test-report.md`: diagnostics and validation evidence.
- `.legion/tasks/auth-mini-acorn-empty-response/docs/review-change.md`: PASS review.

## Verification

- `auth-mini.service` active on Acorn.
- Loopback `GET http://127.0.0.1:7777/web/` returns `200 OK` auth-mini HTML.
- Direct HTTPS to Acorn with SNI for `https://auth.0xc1.wang/web/` returns `HTTP/2 200` auth-mini HTML.
- Cloudflare DoH returns `auth.0xc1.wang A 8.159.128.125`.
- Cloudflare DoH returns `auth-gateway.0xc1.wang A 8.159.128.125`.
- `nix build --impure --no-link .#nixosConfigurations.acorn.config.system.build.toplevel` passed.
- Generated nginx config contains `location = / { return 302 /web/; }`.
- `git diff --check` passed.

## Residual Work

- Merge and switch this repo fix on Acorn to make root-path redirect live.
- If a browser still sees `198.18.x.x`, refresh the browser/proxy DNS cache; Cloudflare DoH already resolves the hostnames to Acorn.
- Auth-mini admin/bootstrap and gateway login smoke remain separate post-deploy work.
