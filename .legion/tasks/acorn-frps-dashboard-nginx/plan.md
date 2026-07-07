# acorn-frps-dashboard-nginx

## Goal

Expose the Acorn frps dashboard through Acorn nginx at `frps-acorn.0xc1.wang`, protected by nginx Basic Auth, without exposing the dashboard port directly.

## Problem

Acorn runs frps for Axiom tunnels, but the frps dashboard is currently not enabled or reachable through nginx. Operators need a browser-accessible view of frps status and proxy statistics. The dashboard is operationally sensitive, so it must not be bound to a public interface or opened as a raw port.

## Acceptance

- Acorn frps enables its dashboard HTTP server on `127.0.0.1:7500`.
- Acorn nginx has an HTTPS vhost for `frps-acorn.0xc1.wang` using DNS-01 ACME.
- Cloudflare DNS has a DNS-only `A` record for `frps-acorn.0xc1.wang` pointing at `8.159.128.125`.
- The nginx vhost proxies to `http://127.0.0.1:7500` and enforces the existing nginx Basic Auth htpasswd secret.
- TCP `7500` is not opened in the NixOS firewall or Aliyun security group by this change.
- The frps control port `7000` and existing tunnel routes remain unchanged.
- No new plaintext dashboard password, frp token, or Cloudflare token is committed.

## Scope

- Update `hosts/acorn/default.nix` for frps dashboard and nginx/ACME config.
- Create or update Cloudflare DNS state for the dashboard hostname.
- Update Legion task docs and wiki decisions for the dashboard exposure boundary.
- Verify Nix evaluation/build and targeted config assertions.

## Non-goals

- Do not expose frps control traffic through nginx.
- Do not enable Cloudflare Access automation for this hostname in this task.
- Do not bind frps dashboard to `0.0.0.0` or open port `7500` publicly.
- Do not add native frps dashboard username/password unless a future task introduces secret-backed rendering for it.
- Do not change Axiom frpc proxies or existing status/OpenCode routes.

## Assumptions

- The existing `nginx-status-htpasswd` secret is acceptable for the frps dashboard Basic Auth boundary.
- The Cloudflare DNS token can manage `0xc1.wang` DNS records.
- DNS-01 ACME can reuse Acorn's existing Cloudflare DNS environment secret.

## Constraints

- Keep public port `80` closed on Acorn; use DNS-01 ACME only.
- Keep dashboard HTTP loopback-only and reachable only through nginx.
- Keep all secrets in agenix or external systems, not in task docs or Nix store templates.

## Risks

- The frps dashboard exposes operational metadata such as proxy names, connection state, and traffic statistics.
- Without Cloudflare Access, nginx Basic Auth is the only user-facing authentication layer for this hostname.
- Live verification requires Acorn deployment privileges and DNS being present.

## Design Summary

- Configure `modules.services.frp.server.extraConfig.webServer.addr = "127.0.0.1"` and `port = 7500`.
- Add `services.nginx.virtualHosts."frps-acorn.0xc1.wang"` with `onlySSL`, `useACMEHost`, `proxyPass`, and `basicAuthFile`.
- Add `security.acme.certs."frps-acorn.0xc1.wang"` using the existing Cloudflare DNS-01 secret.
- Create a DNS-only Cloudflare `A` record for `frps-acorn.0xc1.wang` to `8.159.128.125`.
- Document that `7500` is loopback-only and must not be opened publicly.

## Phases

- Contract and design gate for the dashboard exposure boundary.
- Implement the Acorn frps/nginx/ACME config.
- Verify targeted Nix values, toplevel build, firewall non-exposure, and diff hygiene.
- Review, walkthrough, wiki writeback, PR, merge, cleanup, and deployment handoff.
