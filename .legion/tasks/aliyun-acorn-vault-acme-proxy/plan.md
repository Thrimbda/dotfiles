# Aliyun Acorn Vault ACME Proxy

Status: implemented

## Goal

Restore trusted HTTPS for `vault.0xc1.wang` by enabling Cloudflare-proxied DNS immediately and moving the `aliyun-acorn` origin from a self-signed staging certificate to ACME via Cloudflare DNS-01.

## Problem

`vault.0xc1.wang` was reachable on public `443`, but the origin certificate was self-signed because earlier DNS was missing and public `80` remained closed. That staging shape avoided rebuild failures but produced browser certificate warnings when the DNS record was DNS-only.

## Scope

- Set the Cloudflare `vault.0xc1.wang` A record to `proxied=true` while preserving origin `8.159.128.125`.
- Add an `aliyun-acorn` agenix secret containing `CF_DNS_API_TOKEN` for lego's Cloudflare DNS provider.
- Configure `security.acme.certs."vault.0xc1.wang"` for DNS-01 with `dnsProvider = "cloudflare"`.
- Point the `vault.0xc1.wang` nginx vhost at the ACME host certificate.
- Keep `status-axiom.0xc1.wang` on self-signed staging in this slice.
- Keep public HTTP `80` closed and do not add HTTP-01 challenge handling.

## Non-Goals

- Do not reintroduce `vault.0xc1.space` on `aliyun-acorn`.
- Do not change the existing `hosts/acorn` Vaultwarden deployment.
- Do not migrate Vaultwarden data or create user accounts.
- Do not Terraform-manage Aliyun security group state in this repository.

## Acceptance

- Cloudflare DNS record for `vault.0xc1.wang` is proxied and resolves to Cloudflare edge IPs externally.
- Cloudflare edge returns trusted HTTPS for `vault.0xc1.wang`.
- Nix eval shows `vault.0xc1.wang` nginx uses `useACMEHost = "vault.0xc1.wang"` and no longer uses the self-signed staging path.
- Nix eval shows `security.acme.certs."vault.0xc1.wang"` uses `dnsProvider = "cloudflare"` and an agenix environment file.
- `nix build --impure --no-link .#nixosConfigurations.aliyun-acorn.config.system.build.toplevel` passes.

## Risks

- Source ACME issuance only happens after this config is deployed to `aliyun-acorn`; repository build cannot prove the live ACME order succeeds.
- The current Cloudflare token is powerful enough for DNS writes and must stay encrypted; do not print or store it as plaintext.
- Browser/client DNS caches may briefly continue to hit the old DNS-only path until the proxied record propagates.
