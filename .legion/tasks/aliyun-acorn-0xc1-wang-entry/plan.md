# Aliyun Acorn 0xc1.wang Entry

## Goal

Add a new `0xc1.wang` public entry layer on `aliyun-acorn` while preserving all existing `0xc1.space` Cloudflared routes.

## Problem

`aliyun-acorn` is now the server-side public host and DNS can be configured for a new domain. The repo already has frp from `axiom` to `aliyun-acorn`, but only SSH is exposed through frp. We need a narrow first slice that proves the new domain and nginx/frp path without weakening the existing Cloudflare Access posture for OpenCode.

## Acceptance

- `status-axiom.0xc1.wang` is represented as an nginx vhost on `aliyun-acorn` with HTTPS/ACME and Basic Auth.
- `axiom` exposes Gatus to `aliyun-acorn` through frp TCP proxy `axiom-gatus-http`, local `127.0.0.1:8080`, remote `18080`.
- `18080` remains local-only on `aliyun-acorn`: it must not be opened in NixOS firewall or documented as an Aliyun security-group public port.
- Existing `0xc1.space` cloudflared hostnames remain unchanged.
- `opencode-axiom.0xc1.wang` is not exposed in this task.
- Basic Auth username is `c1`; generated password and htpasswd content are stored only as age secrets under `hosts/aliyun-acorn/secrets/`.
- `axiom.0xc1.wang` is a DNS-only operational step pointing to `aliyun-acorn`; no Nix change is needed for SSH beyond the existing frp `2225` proxy.
- Affected host configs evaluate and dry-run build; generated frp template includes `remotePort = 18080`; nginx vhost references the age-managed htpasswd path.

## Scope

- Update `hosts/axiom/default.nix` frp client proxies.
- Update `hosts/aliyun-acorn/default.nix` with nginx vhost, age secret overrides, and no public `18080` firewall exposure.
- Update `hosts/aliyun-acorn/secrets/secrets.nix` and add encrypted status Basic Auth secrets.
- Add task-local Legion docs, verification, review, walkthrough, and wiki writeback.

## Non-goals

- Do not migrate or remove any `0xc1.space` cloudflared hostname.
- Do not expose `opencode-axiom.0xc1.wang` before a separate Access design.
- Do not move Vaultwarden or unrelated services onto `0xc1.wang`.
- Do not automate Cloudflare DNS in dotfiles; DNS records are operational steps.
- Do not change frp token material unless validation finds it broken.

## Assumptions

- `aliyun-acorn` public IPv4 remains `8.159.128.125`.
- Cloudflare DNS records will be created manually or via an external ops flow: `A status-axiom -> 8.159.128.125`, `A axiom -> 8.159.128.125`, DNS-only.
- `axiom` Gatus remains on local `127.0.0.1:8080`.
- The current frp module supports arbitrary TCP proxy entries and safely injects token at runtime.
- Nginx can read an agenix-managed htpasswd file when the secret owner/group are set to `nginx`.

## Constraints

- Do not print or commit Basic Auth password plaintext.
- Do not expose frp backend port `18080` publicly.
- Keep `2222`, `2223`, `2224` reserved for autossh and `2225` reserved for frp SSH.
- Keep implementation minimal; only add module abstractions if needed for correctness.
- Deliver through the Legion worktree/PR workflow.

## Risks

- Direct nginx exposure removes Cloudflare Access from `status-axiom.0xc1.wang`, so Basic Auth must be present before the hostname is usable.
- ACME validation depends on DNS records pointing to `aliyun-acorn` and public `80/443` reachability in Aliyun security groups.
- Local Nix validation cannot prove deployed frp connectivity, public DNS, ACME issuance, or browser auth behavior.

## Design Summary

Use `aliyun-acorn` as the HTTPS edge for the new `0xc1.wang` status hostname. `axiom` adds a second frp TCP proxy for Gatus on remote `127.0.0.1:18080`. Nginx on `aliyun-acorn` terminates TLS for `status-axiom.0xc1.wang`, enforces Basic Auth through an agenix-managed htpasswd file, and proxies to `http://127.0.0.1:18080`. Existing `0xc1.space` Cloudflared routes remain the safe fallback.

## Phases

1. Materialize task contract and design gate.
2. Implement frp proxy, nginx vhost, and age secrets in an isolated worktree.
3. Validate NixOS configs, generated frp template, nginx auth wiring, and secret shape.
4. Run change review and security lens.
5. Produce walkthrough, PR body, wiki writeback, and complete PR lifecycle.
