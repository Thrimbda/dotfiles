## Summary

- Restore public HTTPS staging for `vault.0xc1.space` and `status-axiom.0xc1.wang` while keeping ACME disabled.
- Add firewall TCP `443`, `2223`, and `2224`; keep public `80` closed.
- Generate temporary self-signed staging certs on-host before nginx config validation.

## Verification

- `nix build --impure --no-link .#nixosConfigurations.aliyun-acorn.config.system.build.toplevel`
- Nix eval checks for firewall ports, HTTPS-only vhosts, no ACME/Docker units, and Docker disabled state.
- Generated nginx config inspection confirmed `443 ssl` listeners and no public `80` listener.

## Notes

- Remote switch remains skipped because `aliyun-acorn` was already timing out during SSH banner exchange.
- Self-signed certs are staging-only; re-enable ACME after DNS/cutover is ready.
