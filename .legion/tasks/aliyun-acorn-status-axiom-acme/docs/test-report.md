# Test Report

## Result

PARTIAL PASS. The repository configuration is valid and builds; live deployment is blocked by remote sudo access.

## Commands

- `nix eval .#nixosConfigurations.aliyun-acorn.config.system.build.toplevel.drvPath`: PASS.
- `nix eval '.#nixosConfigurations.aliyun-acorn.config.security.acme.certs."status-axiom.0xc1.wang".dnsProvider'`: PASS, returns `"cloudflare"`.
- `nix eval '.#nixosConfigurations.aliyun-acorn.config.services.nginx.virtualHosts."status-axiom.0xc1.wang".useACMEHost'`: PASS, returns `"status-axiom.0xc1.wang"`.
- `nix build .#nixosConfigurations.aliyun-acorn.config.system.build.toplevel --dry-run`: PASS, plans `acme-status-axiom.0xc1.wang.service`, `acme-order-renew-status-axiom.0xc1.wang.service`, and `acme-renew-status-axiom.0xc1.wang.timer`.
- `nix build .#nixosConfigurations.aliyun-acorn.config.system.build.toplevel --no-link`: PASS.
- `nix eval '.#nixosConfigurations.aliyun-acorn.config.systemd.services."acme-status-axiom.0xc1.wang".enable'`: PASS, returns `true`.
- `nix eval '.#nixosConfigurations.aliyun-acorn.config.systemd.timers."acme-renew-status-axiom.0xc1.wang".enable'`: PASS, returns `true`.
- `git diff --check`: PASS.
- `nixos-rebuild switch --flake .#aliyun-acorn --target-host c1@8.159.128.125 --use-remote-sudo --fast`: BLOCKED after copying the new closure; remote sudo requires a TTY/password.

## Notes

The blocked deploy did copy `/nix/store/g5wfzmcj41danmdy6syij816h267jfs4-nixos-system-aliyun-acorn-25.11.20260630.b6018f8` to the target host. A privileged remote switch can set that system profile and run `switch-to-configuration switch`.
