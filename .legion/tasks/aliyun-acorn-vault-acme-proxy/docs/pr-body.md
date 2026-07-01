## Summary

- enable Cloudflare proxy for `vault.0xc1.wang`
- add encrypted Cloudflare DNS env secret for `aliyun-acorn` ACME DNS-01
- switch the `vault.0xc1.wang` nginx vhost from self-signed staging to `useACMEHost`
- keep public `80` closed and leave `status-axiom.0xc1.wang` on self-signed staging

## Validation

- Cloudflare API: `vault.0xc1.wang` A record is `proxied=true`
- Cloudflare DoH: `vault.0xc1.wang` resolves to Cloudflare edge IPs
- `curl -I --resolve vault.0xc1.wang:443:104.21.58.171 https://vault.0xc1.wang/`
- `curl -I --resolve vault.0xc1.wang:443:172.67.162.78 https://vault.0xc1.wang/`
- `age -d -i /home/c1/.ssh/id_ed25519 hosts/aliyun-acorn/secrets/cloudflare-dns.env.age | grep -q '^CF_DNS_API_TOKEN='`
- Nix eval for nginx vhost, ACME cert config, and ACME order service
- `nix build --impure --no-link .#nixosConfigurations.aliyun-acorn.config.system.build.toplevel`

## Notes

- Source ACME issuance requires deploying this config to `aliyun-acorn`.
- `hosts/acorn` is unchanged.
