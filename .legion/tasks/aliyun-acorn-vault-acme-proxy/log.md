# Log

## 2026-07-01

- User asked why ACME was not used and requested ACME restore plus Cloudflare `proxied=true`.
- Clarified rationale: ACME was disabled earlier because DNS was NXDOMAIN and public `80` remained closed, so HTTP-01 could fail during switch. With DNS now present, DNS-01 is the safe route.
- Created worktree `.worktrees/aliyun-acorn-vault-acme-proxy` from `origin/master` at `7a4e8926`.
- Updated Cloudflare DNS record `vault.0xc1.wang` to `proxied=true`, preserving origin `8.159.128.125`.
- Added `hosts/aliyun-acorn/secrets/cloudflare-dns.env.age`, encrypted to the `aliyun-acorn` recipient and shaped as an environment file with `CF_DNS_API_TOKEN`.
- Removed `vault.0xc1.wang` from host self-signed staging domains; `status-axiom.0xc1.wang` remains self-signed staging.
- Configured `security.acme.certs."vault.0xc1.wang"` with `dnsProvider = "cloudflare"`, agenix environment file, group `nginx`, and nginx reload.
- Verified Cloudflare DoH returns Cloudflare edge IPs for `vault.0xc1.wang` and edge HTTPS returns `HTTP/2 200` with `server: cloudflare`.
- Verified `nix build --impure --no-link .#nixosConfigurations.aliyun-acorn.config.system.build.toplevel` passes.
