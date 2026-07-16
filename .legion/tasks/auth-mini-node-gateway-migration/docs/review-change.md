# Readiness Review

## Verdict: PASS

## Blocking findings

None.

## Material findings

- Acorn retains `auth-mini`, `auth-mini-gateway-auth-gateway`, and `auth-mini-gateway-frps-acorn` with their existing database paths, encrypted environment file, TLS/ACME setup, and upstream behavior. Only the local status/OpenCode gateway instances are removed.
- The replacement Acorn vhosts proxy all paths to `127.0.0.1:18080/18081`, preserve the literal public `Host`, cookies, WebSocket upgrade, streaming uploads, and unbuffered SSE responses, and contain neither `auth_request` nor upstream cookie clearing.
- The two Axiom gateways bind `127.0.0.1:7779/7780`, use fixed loopback upstreams `127.0.0.1:8080/4096`, and have distinct `0700` state directories and SQLite paths. The rendered units use `/run/agenix/auth-mini-gateway-env`, the dedicated service identity, restrictive write paths/umask, no capabilities, `NoNewPrivileges`, and sensible app/FRP ordering.
- FRP changes only the Gatus/OpenCode local targets to `7779/7780`; SSH remains `22 -> 2225`, and remote ports remain `18080/18081`. Internal app/gateway/FRP remote ports are absent from host firewalls. Existing `.space` Cloudflare routes and application declarations are unchanged.
- The package is pinned to `28a4a273ea9b2725191dce35233f55972beaac6f`; the recorded source and Cargo hashes are supported by a passing package build. The new file is age ciphertext, its rule is Axiom-only, runtime metadata is `auth-mini-gateway:auth-mini-gateway` mode `0400`, and no plaintext secret or SQLite/private runtime state appears in the scoped change.
- The production diff is limited to the package pin, Acorn/Axiom topology, Axiom secret declaration/ciphertext, and small service hardening. No reusable module, custom test infrastructure, or unrelated production change remains.

## Security lens

Applied because authentication, session-secret, network, and upstream trust boundaries change. No public bypass, plaintext-secret exposure, user-controlled upstream selection, or broadened firewall/recipient scope was found. `TRUSTED_PROXY_CIDRS` is intentionally empty, so spoofed forwarding headers cannot influence auth or routing; the trade-off is that application-visible client IP resolves to the direct loopback FRP peer rather than the original client.

## Residuals

- Review relies on the recorded standard package/Axiom build and targeted configuration evaluation. Per the agreed scope, no privileged secret decryption, Acorn closure build, live deployment, or runtime WebSocket/upload/SSE cutover test was required.
- Migration creates fresh Axiom gateway databases and a new cookie secret, so status/OpenCode gateway sessions will reset at cutover as planned.
