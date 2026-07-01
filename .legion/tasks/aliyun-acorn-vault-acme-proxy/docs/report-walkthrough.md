# Walkthrough

## Summary

This change restores trusted HTTPS for `vault.0xc1.wang` in two layers: Cloudflare proxy is enabled immediately for browser-facing trust, and the `aliyun-acorn` origin is prepared to issue a real Let's Encrypt certificate through Cloudflare DNS-01 after deployment.

## Changed

- Cloudflare `vault.0xc1.wang` A record is now proxied.
- Added `cloudflare-dns.env.age` for the lego Cloudflare DNS token used by `aliyun-acorn` ACME.
- `vault.0xc1.wang` nginx now uses `useACMEHost = "vault.0xc1.wang"`.
- `security.acme.certs."vault.0xc1.wang"` uses `dnsProvider = "cloudflare"` and the agenix environment file.
- The self-signed nginx preStart no longer generates a cert for `vault.0xc1.wang`.

## Unchanged

- `status-axiom.0xc1.wang` remains self-signed staging in this task.
- Public HTTP `80` remains closed.
- `hosts/acorn` remains unchanged.
- `vault.0xc1.space` is not deployed on `aliyun-acorn`.

## Deploy Note

Cloudflare proxy is already live. Source ACME issuance starts only after `aliyun-acorn` switches to this config.
