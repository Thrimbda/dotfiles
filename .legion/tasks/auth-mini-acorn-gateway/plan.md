# Auth Mini Gateway on Acorn

## Goal

Deploy `auth-mini` and `auth-mini-gateway` on the canonical `acorn` host, expose them through nginx at `auth.0xc1.wang` and `auth-gateway.0xc1.wang`, and replace the current nginx Basic Auth boundary for Acorn's human-facing reverse-proxy services with gateway-backed `auth_request` authentication.

## Problem

Acorn currently acts as the public ingress for local services: frps exposes private services to loopback ports, and nginx terminates TLS before proxying to those ports. The existing protection for `status-axiom.0xc1.wang`, `opencode-axiom.0xc1.wang`, and `frps-acorn.0xc1.wang` is a shared nginx htpasswd file. That does not provide a reusable session model, passkey-backed login, identity headers, or centralized access policy.

`auth-mini` provides the authentication server and JWT issuer. `auth-mini-gateway` adapts auth-mini sessions to nginx `auth_request`, stores refresh/session material server-side in SQLite, and gives nginx a consistent allow/deny decision for protected upstreams.

## Scope

- Add package/build definitions for `auth-mini` and `auth-mini-gateway` suitable for the `x86_64-linux` Acorn NixOS build.
- Add Acorn systemd services for both binaries, each bound to loopback-only addresses with persistent SQLite state under `/var/lib`.
- Add nginx TLS vhosts for `auth.0xc1.wang` and `auth-gateway.0xc1.wang` using the existing Cloudflare DNS ACME pattern.
- Configure `auth-mini-gateway` with `AUTH_MINI_ISSUER=https://auth.0xc1.wang`, `AUTH_MINI_PUBLIC_BASE_URL=https://auth.0xc1.wang`, HTTPS cookies, persistent DBs, and a secret-backed cookie key/allowlist environment.
- Run origin-scoped gateway instances for `auth-gateway.0xc1.wang`, `status-axiom.0xc1.wang`, `opencode-axiom.0xc1.wang`, and `frps-acorn.0xc1.wang`, because upstream gateway validates returns against a single `GATEWAY_PUBLIC_BASE_URL` and sets host-only cookies.
- Migrate `status-axiom.0xc1.wang`, `opencode-axiom.0xc1.wang`, and `frps-acorn.0xc1.wang` from nginx Basic Auth to their matching origin-scoped gateway `auth_request` flow.
- Keep existing frps and Axiom frpc port mappings intact.

## Non-Goals

- Do not add OAuth/OIDC, social login, or external identity provider integration.
- Do not put `vault.0xc1.wang` behind the gateway in this task. Vaultwarden serves native clients and already has app-level authentication; an interactive front gate could break synchronization and login flows.
- Do not rotate existing Vaultwarden, frp, ACME, or htpasswd secrets.
- Do not expose auth-mini or gateway backend ports directly through the firewall.
- Do not create long-term DNS or Aliyun infrastructure state outside this repository.

## Acceptance Criteria

- `acorn` evaluates and builds with both services enabled.
- `auth-mini` listens only on loopback, uses a durable SQLite DB path, and is reachable publicly only through `https://auth.0xc1.wang` nginx TLS proxying.
- `auth-mini-gateway` instances listen only on loopback, use durable SQLite DB paths, read secret material from agenix, and are reachable publicly only through nginx TLS proxying for their configured hostnames.
- Each gateway-backed vhost exposes the required public routes for login, callback, logout, and health on the same hostname as its `GATEWAY_PUBLIC_BASE_URL`, and keeps the check endpoint internal.
- `status-axiom`, `opencode-axiom`, and `frps-acorn` nginx vhosts use `auth_request` against the local gateway before proxying to their upstreams.
- Protected upstreams continue to support WebSocket upgrade where they did before.
- `vault.0xc1.wang` remains functionally unchanged.
- Required new secrets are declared under `hosts/acorn/secrets` without leaking plaintext.
- Verification records package build/eval, relevant generated nginx shape, firewall shape, and secret declaration checks.

## Assumptions

- The user wants `auth.0xc1.wang` for auth-mini and `auth-gateway.0xc1.wang` for the gateway.
- The forgotten existing nginx reverse proxy in the user's note is `frps-acorn.0xc1.wang`.
- The gateway access policy can be represented by a shared secret environment file containing `GATEWAY_COOKIE_SECRET` plus allowlist fields such as `ALLOW_EMAILS` or `ALLOW_USER_IDS`.
- Auth-mini runtime issuer/RP configuration still requires post-deploy admin setup through its local/admin UI/API; this task supplies the service and ingress, not live admin bootstrap credentials.
- DNS records for the two new hostnames will point to Acorn's public IP, following the existing Cloudflare DNS-only pattern.

## Constraints

- Keep all service backends loopback-only and keep public traffic on nginx-managed HTTPS.
- Do not interpolate secret values into Nix-generated store paths.
- Preserve the current Acorn/Axiom frp port topology.
- Use the repo's existing NixOS module style and agenix secret ownership conventions.
- Treat this as a security-sensitive medium-risk change that requires an RFC, verification, review, walkthrough, and wiki writeback.

## Risks

- Misconfigured gateway issuer or per-origin callback base URL can create login loops or failed callbacks.
- Missing or unstable `GATEWAY_COOKIE_SECRET` invalidates sessions across restarts.
- Incorrect nginx `auth_request` wiring can either bypass authentication or block all traffic.
- Packaging upstream Rust projects from GitHub can fail if the selected source revision has undeclared build assumptions.
- Auth-mini requires post-deploy admin/RP setup before passkey flows are fully usable.

## Recommended Direction

Package both upstream projects declaratively, run them as dedicated system users with durable state directories, and centralize nginx gateway integration in a small Acorn-local helper to avoid repeating fragile `auth_request` boilerplate. Use one gateway service instance per protected origin so upstream return validation and host-only cookies remain correct. Keep the first rollout conservative: protect only the existing human-operated reverse proxies, leave Vaultwarden unchanged, and verify generated nginx and firewall shape before deploy.

## Phases

1. Materialize this contract and create the task checklist.
2. Produce an RFC covering packaging, service hardening, nginx auth flow, secrets, rollback, and verification.
3. Review the RFC and resolve design blockers before implementation.
4. Implement packages, secrets declarations, services, vhosts, and protected reverse proxies in an isolated worktree.
5. Verify Nix eval/build, package builds, generated nginx shape, secret declarations, and firewall exposure.
6. Run readiness review, produce walkthrough/PR body, write back durable wiki knowledge, and complete the PR lifecycle.
