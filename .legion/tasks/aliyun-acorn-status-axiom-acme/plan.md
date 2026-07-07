# aliyun-acorn-status-axiom-acme

## Goal

Switch `status-axiom.0xc1.wang` on `aliyun-acorn` from staged self-signed TLS to a real ACME certificate issued through Cloudflare DNS-01.

## Scope

- Reuse the existing `cloudflare-dns-env.age` agenix secret and ACME DNS provider configuration.
- Keep `status-axiom.0xc1.wang` DNS-only to `8.159.128.125`.
- Keep nginx Basic Auth on the status vhost.
- Keep public port `80` closed; do not use HTTP-01.
- Do not change frp ports, tokens, Gatus, `0xc1.space`, or OpenCode exposure.

## Acceptance

- `aliyun-acorn` NixOS config evaluates.
- `status-axiom.0xc1.wang` has an ACME cert unit using Cloudflare DNS-01.
- After deployment, `https://status-axiom.0xc1.wang` presents a browser-trusted certificate and returns `401 Basic Auth` without `-k`.
