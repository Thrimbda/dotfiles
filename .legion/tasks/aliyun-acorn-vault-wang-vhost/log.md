# Log: Aliyun Acorn Vault Wang Vhost

## 2026-07-01

- User reported `vault.0xc1.wang` is inaccessible after switching remote host.
- SSH to `c1@8.159.128.125` now reaches OpenSSH but rejects the expected public key with `Permission denied (publickey)`.
- Local eval shows `users.users.c1.openssh.authorizedKeys.keys` includes `/home/c1/.ssh/id_ed25519.pub`, so live machine SSH auth state must be inspected from console or another recovery path.
- Local eval showed nginx vhosts only included `status-axiom.0xc1.wang` and `vault.0xc1.space`; there was no `vault.0xc1.wang` vhost.
- External curl to `vault.0xc1.wang` and `vault.0xc1.space` on `8.159.128.125:443` failed with TLS EOF, so live nginx status still needs remote logs.
- Added `vault.0xc1.wang` to staged TLS cert generation and nginx vhosts.
- Set Vaultwarden public domain to `https://vault.0xc1.wang`.

## Verification

- Vhost eval: `status-axiom.0xc1.wang`, `vault.0xc1.space`, and `vault.0xc1.wang` are present.
- Vaultwarden domain eval: `https://vault.0xc1.wang`.
- `vault.0xc1.wang` eval has `onlySSL = true`, `enableACME = false`, self-signed cert path, and the expected proxy locations.
- ACME/Docker unit filter returned `[]`.
- `nix build --impure --no-link .#nixosConfigurations.aliyun-acorn.config.system.build.toplevel` passed.
- Generated nginx config contains public `443 ssl` server blocks for `vault.0xc1.space` and `vault.0xc1.wang`.
- Generated nginx preStart includes `vault.0xc1.wang` cert generation.
