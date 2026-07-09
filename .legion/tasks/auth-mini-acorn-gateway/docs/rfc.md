# RFC: Auth Mini Gateway on Acorn

## Status

Proposed for review.

## Context

Acorn is the public ingress host for several services. It currently runs frps and nginx. Axiom reaches Acorn through frpc remote TCP ports, and Acorn nginx publishes selected services over HTTPS:

- `status-axiom.0xc1.wang` -> `http://127.0.0.1:18080`
- `opencode-axiom.0xc1.wang` -> `http://127.0.0.1:18081`
- `frps-acorn.0xc1.wang` -> `http://127.0.0.1:7500`
- `vault.0xc1.wang` -> local Vaultwarden service

The first three are human-operated reverse-proxy surfaces protected today by nginx Basic Auth. Vaultwarden is different: it is an application with its own auth and native clients, so putting it behind a browser login gateway risks breaking non-browser flows.

Upstream behavior relevant to deployment:

- `auth-mini` is a Rust server binary. The deployment CLI accepts only `--host`, `--port`, and `--db`. It initializes SQLite schema/JWKS automatically, serves the embedded web UI at `/web/`, and stores issuer/RP/SMTP in app metadata configured after bootstrap.
- `auth-mini-gateway` is a Rust/SQLite nginx `auth_request` adapter. It needs `GATEWAY_PUBLIC_BASE_URL`, `AUTH_MINI_ISSUER`, durable `GATEWAY_DB`, stable `GATEWAY_COOKIE_SECRET`, and an allowlist. It keeps browser cookies opaque and stores auth-mini tokens server-side.

## Decision

Deploy two loopback-only systemd services on Acorn:

1. `auth-mini`
   - Binary source: upstream Linux x86_64 release asset from `zccz14/auth-mini` tag `latest`, pinned by fixed output hash.
   - Listener: `127.0.0.1:7777`.
   - Database: `/var/lib/auth-mini/auth-mini.sqlite`.
   - Public vhost: `auth.0xc1.wang`.
   - nginx proxies all normal paths to the local listener and keeps TLS/ACME consistent with existing Acorn vhosts.

2. `auth-mini-gateway`
   - Binary source: `Thrimbda/auth-mini-gateway` pinned to `f3df1c0300e67468348eeb6f012abd85b8681081`, built with `rustPlatform.buildRustPackage` and a checked `Cargo.lock` vendor hash.
   - Runtime model: one origin-scoped service instance per public hostname that needs gateway routes.
   - Listeners: loopback-only ports allocated per instance.
   - Databases: one SQLite DB per instance under `/var/lib/auth-mini-gateway/`.
   - Public vhosts: `auth-gateway.0xc1.wang`, `status-axiom.0xc1.wang`, `opencode-axiom.0xc1.wang`, and `frps-acorn.0xc1.wang`.
   - Environment baseline per instance:
     - `HOST=127.0.0.1`
     - `PORT=<instance port>`
     - `GATEWAY_PUBLIC_BASE_URL=https://<instance hostname>`
     - `AUTH_MINI_ISSUER=https://auth.0xc1.wang`
     - `AUTH_MINI_PUBLIC_BASE_URL=https://auth.0xc1.wang`
     - `GATEWAY_DB=/var/lib/auth-mini-gateway/<instance>.sqlite`
     - `COOKIE_SECURE=true`
     - `COOKIE_SAME_SITE=lax`
     - `REQUIRE_PASSKEY=true` unless overridden by secret env during deploy readiness
   - Secret env file: agenix-managed `auth-mini-gateway-env.age`, owned by the gateway service user/group, containing at least `GATEWAY_COOKIE_SECRET` and one allowlist variable such as `ALLOW_EMAILS` or `ALLOW_USER_IDS`.

## nginx Model

Create an Acorn-local helper for gateway routes and protected vhosts so the auth pattern is repeated consistently.

Important upstream constraint: current `auth-mini-gateway` validates `return_to` against a single `GATEWAY_PUBLIC_BASE_URL` and emits host-only cookies. A single central `auth-gateway.0xc1.wang` instance cannot safely complete login for `status-axiom.0xc1.wang` or `opencode-axiom.0xc1.wang`. Therefore each protected hostname gets its own gateway instance with `GATEWAY_PUBLIC_BASE_URL` set to that hostname. `auth-gateway.0xc1.wang` still exists as the canonical gateway service hostname and health/login surface, but it is not used as a cross-host callback endpoint for all protected services.

Instance allocation:

- `auth-gateway.0xc1.wang` -> `127.0.0.1:7778`, DB `auth-gateway.sqlite`
- `status-axiom.0xc1.wang` -> `127.0.0.1:7779`, DB `status-axiom.sqlite`
- `opencode-axiom.0xc1.wang` -> `127.0.0.1:7780`, DB `opencode-axiom.sqlite`
- `frps-acorn.0xc1.wang` -> `127.0.0.1:7781`, DB `frps-acorn.sqlite`

Each gateway-backed public vhost exposes the gateway's own routes on that same host:

- `/healthz`
- `/login`
- `/auth/callback`
- `/auth/callback/session`
- `/logout`

It also owns the internal check location:

- `/_auth` -> that hostname's local gateway instance `/auth/check`

Protected service vhosts use their matching local gateway check directly:

- internal location `/_auth` proxies to that hostname's local gateway instance `/auth/check`
- protected location runs `auth_request /_auth`
- `401` routes to an internal login redirect location that proxies to `http://127.0.0.1:7778/login`
- `403` returns a local forbidden response
- upstream cookies are stripped unless a protected service explicitly needs browser cookies
- identity headers from gateway are passed as `X-Auth-Mini-User-Id` and `X-Auth-Mini-Email`
- WebSocket vhosts preserve `proxyWebsockets = true` and HTTP/1.1 upgrade behavior

The three protected vhosts are:

- `status-axiom.0xc1.wang`
- `opencode-axiom.0xc1.wang`
- `frps-acorn.0xc1.wang`

`vault.0xc1.wang` remains unchanged.

## Secrets

Add `hosts/acorn/secrets/auth-mini-gateway-env.age` to `hosts/acorn/secrets/secrets.nix` for the Acorn recipient.

Expected plaintext shape:

```env
GATEWAY_COOKIE_SECRET=<stable random secret, at least 32 chars>
ALLOW_EMAILS=<comma-separated allowed emails>
ALLOW_USER_IDS=
REQUIRE_PASSKEY=true
```

`REQUIRE_PASSKEY` may be kept in Nix or the secret env. Keeping it in the secret env lets the deployer temporarily relax policy during bootstrap without changing the Nix closure. The service should load the non-secret baseline first and the secret env second so explicit secret env values can override bootstrap-sensitive policy. The same secret env can be reused by all origin-scoped gateway instances, but each instance must use its own SQLite DB to avoid multi-active shared-DB behavior.

No auth-mini SMTP or admin key secret is declared by this task. Upstream auth-mini supports local admin setup without SMTP, and SMTP/admin configuration is a post-deploy operational step.

## Service Hardening

Both services should run as dedicated system users with state directories under `/var/lib`.

Baseline systemd hardening:

- `NoNewPrivileges=true`
- `PrivateTmp=true`
- `ProtectSystem=strict`
- `ProtectHome=true`
- `ReadWritePaths` limited to the service state directory
- restart on failure
- network-online ordering

The gateway service additionally reads the agenix secret env file.

## Alternatives Considered

### Keep nginx Basic Auth

Rejected. It is simpler but does not meet the goal of centralized auth-mini sessions, passkey policy, server-side token storage, and identity headers.

### Put Vaultwarden Behind Gateway Too

Rejected for this task. Vaultwarden native clients expect direct app protocol behavior. A browser-oriented external auth gate can break app login, sync, mobile clients, or API calls. This can be reconsidered only with a Vaultwarden-specific compatibility design.

### Build auth-mini From Source

Deferred. Source build has more moving parts because the deployed server embeds UI/static assets and the upstream docs explicitly recommend release binaries for deployment. The fixed-hash release artifact gives a smaller rollout surface. If the mutable `latest` tag becomes unacceptable, follow up by pinning an immutable upstream release tag once one exists.

### Single Central Gateway for All Protected Hosts

Rejected with current upstream behavior. `auth-mini-gateway` normalizes return targets against `GATEWAY_PUBLIC_BASE_URL` and does not set a cookie domain, so a central `auth-gateway.0xc1.wang` callback would not receive login-state cookies created under another protected host, and cross-host return targets would be rejected. Origin-scoped instances are the smallest safe design without patching upstream gateway semantics.

## Rollback

Rollback is config-only:

1. Restore `status-axiom`, `opencode-axiom`, and `frps-acorn` vhosts to their previous `basicAuthFile = config.age.secrets.nginx-status-htpasswd.path` locations.
2. Remove or disable the two new public vhosts if auth service rollback is required.
3. Stop `auth-mini` and `auth-mini-gateway` services.
4. Keep `/var/lib/auth-mini*` state intact unless intentionally abandoning the deployment; deleting the gateway DB revokes gateway sessions, and deleting the auth-mini DB loses auth users/keys/config.

The previous htpasswd secret remains declared so rollback does not require secret recovery.

## Verification Plan

Static and build checks:

- `nix build --no-link .#packages.x86_64-linux.auth-mini`
- `nix build --no-link .#packages.x86_64-linux.auth-mini-gateway`
- `nix eval --raw .#nixosConfigurations.acorn.config.networking.hostName`
- `nix build --impure --no-link .#nixosConfigurations.acorn.config.system.build.toplevel`
- evaluate nginx virtual hosts for new hostnames, per-origin gateway routes, protected auth locations, and unchanged Vaultwarden vhost
- evaluate firewall ports to confirm only existing public ports plus nginx/frps ports remain and backend service ports are not opened
- check `hosts/acorn/secrets/secrets.nix` declares `auth-mini-gateway-env.age` without plaintext

Post-deploy checks outside local build scope:

- DNS-only Cloudflare records exist for `auth.0xc1.wang` and `auth-gateway.0xc1.wang`.
- ACME issues both certs.
- auth-mini admin setup configures issuer `https://auth.0xc1.wang` and RP ID `auth.0xc1.wang`.
- unauthenticated access to protected vhosts redirects to gateway/auth-mini login.
- allowed passkey-backed user reaches protected services.
- non-allowed user receives 403.
- logout revokes gateway session.
- WebSocket-dependent Opencode path still connects after login.

## Open Notes

- The exact allowlist values are secret operational data and intentionally not recorded in the RFC.
- `auth-mini` release tag `latest` is mutable upstream. Nix fixed-output hashing prevents silent mutation but may require a follow-up hash update when upstream refreshes the tag.
