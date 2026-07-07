# axiom-opencode-wang-frp

## Goal

Add a parallel `opencode-axiom.0xc1.wang` entrypoint for Axiom OpenCode through `axiom` frpc, `aliyun-acorn` frps/nginx, Cloudflare DNS, and DNS-01 ACME, without replacing the existing `opencode-axiom.0xc1.space` Cloudflared path.

## Problem

`opencode-axiom.0xc1.space` currently reaches Axiom through the `home-axiom` Cloudflare Tunnel and is protected by Cloudflare Access. The user wants an additional `0xc1.wang` route that uses the existing Acorn/frp ingress pattern. OpenCode is sensitive, so a raw nginx/frp origin must not become directly usable without authentication or be mistaken for a replacement of the existing Cloudflared route.

## Acceptance

- `axiom` has a new frpc proxy from local OpenCode `127.0.0.1:4096` to an `aliyun-acorn` remote backend port reserved for nginx only.
- `aliyun-acorn` has an nginx vhost for `opencode-axiom.0xc1.wang` with DNS-01 ACME and websocket-capable proxying to the frp backend.
- `opencode-axiom.0xc1.wang` has a Cloudflare DNS record pointing at `8.159.128.125` and remains protected by Cloudflare Access.
- Origin bypass is still protected by nginx Basic Auth, and the frp backend port is not opened in NixOS firewall or Aliyun security group.
- Existing `opencode-axiom.0xc1.space`, `status-axiom.0xc1.space`, and `0xc1.space` Cloudflared routes remain unchanged.
- No frp token, Cloudflare token, Basic Auth password, or Access secret is printed or committed.

## Scope

- Add `axiom-opencode-http` frpc proxy on Axiom.
- Add `opencode-axiom.0xc1.wang` nginx and ACME config on `aliyun-acorn`.
- Create or update Cloudflare DNS and Access state for the new hostname.
- Record verification, security review, walkthrough, and wiki updates.

## Non-goals

- Do not migrate or remove `opencode-axiom.0xc1.space`.
- Do not expose OpenCode directly on Acorn without authentication.
- Do not open the OpenCode frp backend port in public firewall/security-group rules.
- Do not redesign OpenCode service management or Cloudflared module behavior.
- Do not change `status-axiom.0xc1.wang` or Gatus behavior except for shared documentation context.

## Assumptions

- Axiom OpenCode remains available on `127.0.0.1:4096` via `modules.services.opencode-server`.
- Acorn frps is reachable from Axiom on TCP `7000`, and the existing direct-route service remains sufficient.
- The Cloudflare DNS token can manage `0xc1.wang` DNS and the canonical Cloudflare API token can manage Access state.
- Double auth is acceptable for the new route: Cloudflare Access at the edge plus nginx Basic Auth at the origin.

## Constraints

- Keep public port `80` closed on Acorn; use DNS-01 ACME only.
- Keep the OpenCode frp backend port behind nginx and local firewall/security-group boundaries.
- Preserve all existing `0xc1.space` behavior.
- Do not write plaintext secrets to Git, task docs, PR body, shell history, or logs.

## Risks

- Cloudflare Access protects proxied traffic, but direct origin access by IP and Host header would bypass Access unless nginx Basic Auth is kept.
- Live deployment requires switching both Axiom and Acorn NixOS configurations; either may require sudo/root authorization outside this agent.
- Cloudflare DNS/Access API changes are live external state and must be verified after mutation.

## Design Summary

- Use `opencode-axiom.0xc1.wang` as a parallel hostname.
- Configure Cloudflare DNS as a proxied `A` record to `8.159.128.125`, enabling Cloudflare Access at the edge.
- Configure Acorn nginx with `onlySSL`, `useACMEHost`, DNS-01 ACME, `proxyWebsockets = true`, and Basic Auth.
- Use frp remote TCP `18081` as the nginx-only backend for Axiom OpenCode; do not open it publicly.

## Phases

- Contract and design: confirm parallel `.wang` route and authentication boundary.
- Implementation: update Axiom frpc and Acorn nginx/ACME config.
- Cloudflare: create/update DNS and Access state for the new hostname.
- Verification: evaluate/build NixOS configs and verify Cloudflare state shape.
- Review and delivery: write review/walkthrough/wiki evidence, PR, merge, cleanup, and deployment handoff or live verification.
