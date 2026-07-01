# Aliyun Acorn Vault ACME Proxy

Status: ready for PR

## Summary

Restores trusted HTTPS for `vault.0xc1.wang` by enabling Cloudflare proxy immediately and preparing the `aliyun-acorn` origin to use Let's Encrypt via Cloudflare DNS-01.

## Current Shape

- Cloudflare `vault.0xc1.wang` A record is proxied and points at origin `8.159.128.125`.
- External resolvers return Cloudflare edge IPs for `vault.0xc1.wang`.
- `aliyun-acorn` stores the Cloudflare DNS token as `hosts/aliyun-acorn/secrets/cloudflare-dns.env.age` with `CF_DNS_API_TOKEN` for lego.
- `security.acme.certs."vault.0xc1.wang"` uses `dnsProvider = "cloudflare"` and `webroot = null`, so public `80` is not required.
- `vault.0xc1.wang` nginx uses `useACMEHost = "vault.0xc1.wang"`.

## Follow-Up

- Deploy `aliyun-acorn` and confirm `acme-order-renew-vault.0xc1.wang.service`, `acme-vault.0xc1.wang.service`, and `nginx.service` are healthy on the host.
