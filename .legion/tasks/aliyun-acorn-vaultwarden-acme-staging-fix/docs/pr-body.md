## Summary

- Slim `aliyun-acorn` for its low-resource server role by removing dev runtimes, media tooling, Docker, host `nix-ld`, and local docs.
- Limit on-host Nix resource usage and switch SSH back to normal daemon mode for better banner responsiveness under load.
- Keep Vaultwarden staged, but make Vaultwarden/status nginx vhosts local-only and remove public `80/443` until DNS/TLS cutover.

## Verification

- `nix build --impure --no-link .#nixosConfigurations.aliyun-acorn.config.system.build.toplevel`
- Nix eval checks for Vaultwarden enabled, no ACME units, no Docker units, local-only nginx listeners, forced firewall ports, SSH daemon mode, and Nix resource limits.
- Closure comparison: `5.5 GiB` baseline to `3.2 GiB` after slimming.

## Notes

- Remote switch was skipped because `aliyun-acorn` still times out during SSH banner exchange.
- Re-enable public `80/443` and ACME for `vault.0xc1.space` / `status-axiom.0xc1.wang` only after DNS/TLS cutover is ready.
