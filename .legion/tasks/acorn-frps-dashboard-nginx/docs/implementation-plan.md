# Implementation Plan

## Files

- `hosts/acorn/default.nix`
- `.legion/wiki/decisions.md`
- `.legion/tasks/acorn-frps-dashboard-nginx/**`

## Steps

1. Add Acorn frps dashboard settings under `modules.services.frp.server.extraConfig.webServer` with loopback addr and port `7500`.
2. Add Acorn nginx vhost `frps-acorn.0xc1.wang` with `onlySSL`, `useACMEHost`, `proxyPass = "http://127.0.0.1:7500"`, and Basic Auth.
3. Add DNS-01 ACME cert config for `frps-acorn.0xc1.wang` using the existing Cloudflare DNS env secret.
4. Create or update the Cloudflare DNS-only `A` record for `frps-acorn.0xc1.wang`.
5. Update wiki decisions to record the dashboard exposure boundary.
6. Run targeted Nix evals and Acorn toplevel validation.
7. Record verification, review, walkthrough, PR body, and deployment status.
