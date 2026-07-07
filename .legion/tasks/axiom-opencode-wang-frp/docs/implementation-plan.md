# Implementation Plan

## Files

- `hosts/axiom/default.nix`
- `hosts/aliyun-acorn/default.nix`
- `.legion/wiki/decisions.md`
- `.legion/tasks/axiom-opencode-wang-frp/**`

## Steps

1. Add `axiom-opencode-http` frpc proxy: `127.0.0.1:4096 -> 18081`.
2. Add Acorn nginx vhost `opencode-axiom.0xc1.wang` with `onlySSL`, `useACMEHost`, `proxyWebsockets`, and Basic Auth.
3. Add Acorn ACME cert `opencode-axiom.0xc1.wang` using Cloudflare DNS-01.
4. Update wiki decisions to record the new `.wang` OpenCode route and double-auth boundary.
5. Create/update Cloudflare proxied A record and Access app/policy.
6. Run targeted Nix and Cloudflare checks.
7. Record verification/review/walkthrough and deliver through PR.
