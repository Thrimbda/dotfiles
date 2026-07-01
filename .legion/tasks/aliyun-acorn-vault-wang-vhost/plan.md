# Aliyun Acorn Vault Wang Vhost

## Goal

Make `vault.0xc1.wang` the public Vaultwarden staging hostname on `aliyun-acorn` while preserving the existing `vault.0xc1.space` compatibility vhost.

## Acceptance

- `vault.0xc1.wang` exists as an nginx HTTPS-only vhost.
- `vault.0xc1.wang` uses the same Vaultwarden proxy routes as `vault.0xc1.space`.
- Vaultwarden's configured public `domain` is `https://vault.0xc1.wang`.
- Staged self-signed TLS cert generation includes `vault.0xc1.wang`.
- ACME remains disabled and no ACME units are generated.
- Toplevel build passes.

## Notes

Live SSH to `c1@8.159.128.125` currently fails with `Permission denied (publickey)` even though local evaluation includes the expected public key in `users.users.c1.openssh.authorizedKeys.keys`. Console-side inspection is required for remote logs.
