## Summary

- Add `vault.0xc1.wang` as an HTTPS-only staged Vaultwarden vhost on `aliyun-acorn`.
- Set Vaultwarden's public domain to `https://vault.0xc1.wang`.
- Keep `vault.0xc1.space` as a compatibility vhost and keep ACME disabled for staging.

## Verification

- `nix build --impure --no-link .#nixosConfigurations.aliyun-acorn.config.system.build.toplevel`
- Nix eval checks for vhost names, Vaultwarden domain, HTTPS-only vhost shape, and no ACME/Docker units.
- Generated nginx config inspection confirmed the `vault.0xc1.wang` `443 ssl` server block.

## Note

- Remote inspection is currently blocked because SSH rejects the expected public key.
