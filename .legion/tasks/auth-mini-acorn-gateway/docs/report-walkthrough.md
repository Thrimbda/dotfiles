# Walkthrough: Auth Mini Gateway on Acorn

Mode: implementation

## Summary

This change deploys `auth-mini` and `auth-mini-gateway` into Acorn's nginx/frps ingress path. `auth-mini` is exposed at `auth.0xc1.wang`; gateway routes are exposed at `auth-gateway.0xc1.wang` and per protected hostname. The existing Basic Auth boundary for `status-axiom.0xc1.wang`, `opencode-axiom.0xc1.wang`, and `frps-acorn.0xc1.wang` is replaced with gateway-backed nginx `auth_request`.

Vaultwarden remains unchanged because it has native clients and app-level authentication.

## Design Point To Review

The gateway is not deployed as one central cross-host callback endpoint. Upstream `auth-mini-gateway` validates `return_to` against one `GATEWAY_PUBLIC_BASE_URL` and sets host-only cookies. The implementation therefore runs one gateway instance per protected origin:

- `auth-gateway.0xc1.wang` -> `127.0.0.1:7778`
- `status-axiom.0xc1.wang` -> `127.0.0.1:7779`
- `opencode-axiom.0xc1.wang` -> `127.0.0.1:7780`
- `frps-acorn.0xc1.wang` -> `127.0.0.1:7781`

This is documented in `docs/rfc.md` and accepted in `docs/review-rfc.md`.

## Implementation

- Added `packages/auth-mini`, using the upstream Linux x86_64 release tarball pinned by fixed hash.
- Added `packages/auth-mini-gateway`, using `rustPlatform.buildRustPackage` from pinned commit `f3df1c0300e67468348eeb6f012abd85b8681081` and fixed cargo vendor hash.
- Added `hosts/acorn/modules/auth-mini.nix` with dedicated system users, loopback-only services, persistent SQLite state, nginx vhosts, and ACME declarations for the new auth hostnames.
- Added encrypted `hosts/acorn/secrets/auth-mini-gateway-env.age` and declared it in `hosts/acorn/secrets/secrets.nix`.
- Removed the old Basic Auth nginx locations for status/opencode/frps from `hosts/acorn/default.nix`; the new module owns those vhosts.

## Verification

Repository-level validation passed. Evidence is in `docs/test-report.md`.

Key checks:

- `auth-mini` package build passed.
- `auth-mini-gateway` package build passed and upstream Rust tests passed `11 passed`.
- Acorn toplevel build passed.
- Firewall eval excludes backend ports `7777` through `7781`.
- Generated nginx config contains full public hostnames and per-origin gateway ports.
- Protected vhost locations include `auth_request /_auth` and have `basicAuthFile=null`.
- Vaultwarden still proxies to `127.0.0.1:8000` and websocket route `127.0.0.1:3012`.
- New gateway secret decrypts with the Acorn identity without printing plaintext.

## Review Result

`docs/review-change.md` records PASS. Security lens was applied because this changes auth/session/secrets/trust boundaries. No blocking findings remain.

## Post-Deploy Checklist

- Create/verify DNS-only Cloudflare records for `auth.0xc1.wang` and `auth-gateway.0xc1.wang`.
- Switch Acorn and confirm `auth-mini` plus all `auth-mini-gateway-*` services are active.
- Confirm ACME cert issuance for the two new hostnames.
- Bootstrap auth-mini admin and configure issuer `https://auth.0xc1.wang` plus RP ID `auth.0xc1.wang`.
- Browser-test unauthenticated redirect, allowed user access, denied user `403`, logout, and Opencode WebSocket behavior.
