## Summary

- remove `vault.0xc1.space` from `aliyun-acorn` staged TLS cert generation
- remove `vault.0xc1.space` from `aliyun-acorn` Vaultwarden nginx vhosts
- keep `vault.0xc1.wang` as the only Vaultwarden hostname on `aliyun-acorn`

## Validation

- `nix eval --impure --json .#nixosConfigurations.aliyun-acorn.config.services.nginx.virtualHosts --apply 'vhosts: builtins.attrNames vhosts'`
- `nix eval --impure --json .#nixosConfigurations.aliyun-acorn.config.services.vaultwarden.config.domain`
- `nix eval --impure --json .#nixosConfigurations.aliyun-acorn.config.systemd.services.nginx.preStart`
- `nix eval --impure --json .#nixosConfigurations.aliyun-acorn.config.systemd.services --apply 'services: builtins.filter (name: builtins.match ".*(acme|docker).*" name != null) (builtins.attrNames services)'`
- `nix build --impure --no-link .#nixosConfigurations.aliyun-acorn.config.system.build.toplevel`

## Notes

- `hosts/acorn` is unchanged.
