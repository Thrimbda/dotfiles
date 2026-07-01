# Walkthrough: Aliyun Acorn Vault Wang Vhost

## Summary

Adds `vault.0xc1.wang` as the intended public Vaultwarden staging hostname on `aliyun-acorn`, while keeping the previous `vault.0xc1.space` vhost as compatibility routing.

## Verification

- Nix eval confirms vhost presence, Vaultwarden domain, HTTPS-only vhost shape, and no ACME units.
- Toplevel build passed.
- Generated nginx config contains the expected `vault.0xc1.wang` `443 ssl` server block.

## Operational Note

Remote inspection is currently blocked because the host rejects the expected SSH key.
