## Summary

- Add an Axiom-local direct route service for `8.159.128.125/32` through the `main` table.
- Order `frpc.service` after/requires/wants that route service so frpc bypasses Clash/Meta TUN when dialing Aliyun Acorn.
- Keep the fix host-local; no frp module, Clash module, secret, nginx, or firewall-port changes.

## Validation

- `nix eval --raw ...#nixosConfigurations.axiom.config.system.build.toplevel.drvPath`
- `nix build --dry-run ...#nixosConfigurations.axiom.config.system.build.toplevel`
- Evaluated `frpc.service` dependencies include `frpc-aliyun-acorn-direct-route.service`.
- Evaluated route service unit and route script; script passed `bash -n`.

## Post-deploy

- Confirm `ip route get 8.159.128.125 uid 1000` uses the main LAN route, not `dev Meta table 2022`.
- Confirm `frpc.service` remains active and `aliyun-acorn` frps registers `2225` and `18080`.
