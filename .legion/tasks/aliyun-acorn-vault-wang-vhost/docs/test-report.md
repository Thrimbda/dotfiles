# Test Report: Aliyun Acorn Vault Wang Vhost

## Results

- `nix eval --impure --json .#nixosConfigurations.aliyun-acorn.config.services.nginx.virtualHosts --apply 'v: builtins.attrNames v'` returned `status-axiom.0xc1.wang`, `vault.0xc1.space`, and `vault.0xc1.wang`.
- `nix eval --impure --json .#nixosConfigurations.aliyun-acorn.config.services.vaultwarden.config.domain` returned `https://vault.0xc1.wang`.
- `vault.0xc1.wang` evaluates with `onlySSL = true`, `enableACME = false`, and locations `/`, `/notifications/hub`, `/notifications/hub/negotiate`.
- ACME/Docker unit filter returned `[]`.
- `nix build --impure --no-link .#nixosConfigurations.aliyun-acorn.config.system.build.toplevel` passed.
- Generated nginx config inspected at `/nix/store/z8g3lpkbm6kvlzy27s0dfcx3zlp8iy8k-nginx.conf` contains a `vault.0xc1.wang` `443 ssl` server block.

## Skipped

- Remote service inspection was skipped because SSH rejects the expected public key.
