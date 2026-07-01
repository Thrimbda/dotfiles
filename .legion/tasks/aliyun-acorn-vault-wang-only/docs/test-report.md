# Test Report

## Result

Pass.

## Evidence

- `nix eval --impure --json .#nixosConfigurations.aliyun-acorn.config.services.nginx.virtualHosts --apply 'vhosts: builtins.attrNames vhosts'`
  - `["status-axiom.0xc1.wang","vault.0xc1.wang"]`
- `nix eval --impure --json .#nixosConfigurations.aliyun-acorn.config.services.vaultwarden.config.domain`
  - `"https://vault.0xc1.wang"`
- `nix eval --impure --json .#nixosConfigurations.aliyun-acorn.config.systemd.services.nginx.preStart`
  - domain loop contains `status-axiom.0xc1.wang vault.0xc1.wang`
  - domain loop does not contain `vault.0xc1.space`
- `grep vault\.0xc1\.space hosts/aliyun-acorn/**/*.nix`
  - no matches
- `nix eval --impure --json .#nixosConfigurations.aliyun-acorn.config.systemd.services --apply 'services: builtins.filter (name: builtins.match ".*(acme|docker).*" name != null) (builtins.attrNames services)'`
  - `[]`
- `nix build --impure --no-link .#nixosConfigurations.aliyun-acorn.config.system.build.toplevel`
  - pass
