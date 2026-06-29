# Walkthrough: Axiom FRPC Direct Route

Mode: implementation

## What Changed

- Added `frpc-aliyun-acorn-direct-route.service` on `axiom`.
- The route service installs `ip rule priority 8500 to 8.159.128.125/32 lookup main`.
- Ordered `frpc.service` after/requires/wants the route service.
- Reused one `aliyunAcornPublicIp` local binding for reverse SSH and frp server address.

## Why

Runtime diagnosis showed `frpc` traffic to `8.159.128.125` was routed through `dev Meta table 2022`, while `aliyun-acorn` `frps` was active but saw no incoming traffic. The fix makes Axiom treat Aliyun Acorn as a direct remote-access endpoint instead of proxying it through Clash/Meta.

## Reviewer Focus

- `hosts/axiom/default.nix`: route service should be host-local and limited to `8.159.128.125/32`.
- `hosts/axiom/default.nix`: `frpc.service` should require/start after `frpc-aliyun-acorn-direct-route.service`.
- The change should not alter `modules/services/frp.nix`, Clash Verge module behavior, secrets, or firewall ports.

## Validation Evidence

- `nix eval` Axiom toplevel passed.
- `nix build --dry-run` Axiom toplevel passed.
- Evaluated `frpc.service` includes `After=`, `Wants=`, and `Requires=` for the direct-route service.
- Evaluated route service unit includes `Before=frpc.service`, `After=network-online.target clash-verge.service`, and `WantedBy=multi-user.target`.
- Evaluated route service script passed `bash -n`.

Evidence source: `docs/test-report.md`.

## Review Evidence

Change review passed with the network/security lens applied.

Evidence source: `docs/review-change.md`.

## Post-deploy Checks

- `ip rule show | grep 8500`
- `ip route get 8.159.128.125 uid 1000` should not use `dev Meta table 2022`.
- `systemctl status frpc` should stay active.
- On `aliyun-acorn`, `ss -lntp '( sport = :7000 or sport = :2225 or sport = :18080 )'` should show registered remote frp listeners after Axiom connects.
