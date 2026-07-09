## Summary

- fix `auth.0xc1.wang/` to redirect to auth-mini UI at `/web/`
- record live diagnosis for the post-switch empty response
- document that missing Cloudflare DNS records were created for `auth.0xc1.wang` and `auth-gateway.0xc1.wang`

## Root Cause

`auth-mini.service` was healthy on Acorn and `/web/` returned HTML when requests reached `8.159.128.125`. The browser empty response came from missing Cloudflare DNS records, which caused fake-ip/proxy DNS resolution instead of Acorn. The repo-owned gap was that `/` returned auth-mini API `404` while the UI lives at `/web/`.

## Verification

- `nix build --impure --no-link .#nixosConfigurations.acorn.config.system.build.toplevel`
- `git diff --check`
- live Acorn service diagnostics: `auth-mini.service` active, loopback `/web/` 200
- direct HTTPS/SNI smoke: `https://auth.0xc1.wang/web/` 200 via `8.159.128.125`
- Cloudflare DoH confirms `auth.0xc1.wang` and `auth-gateway.0xc1.wang` A records point to `8.159.128.125`

## Notes

After this PR is switched on Acorn, `https://auth.0xc1.wang/` should return `302 Location: /web/`.
