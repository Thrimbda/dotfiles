# Log: Axiom FRPC Direct Route

## 2026-06-29

- User reported `frpc` still failing after `frps` was deployed.
- Runtime diagnosis showed `aliyun-acorn` `frps` active on `*:7000` but no incoming frps traffic accounting/logs, while `axiom` routes `8.159.128.125` through `dev Meta table 2022`.
- Temporary runtime route validation could not be applied from the agent because local `sudo -n` was unavailable.
- Selected a host-local Nix route service for `axiom` as the minimal durable fix.
- Implemented `frpc-aliyun-acorn-direct-route.service` and ordered `frpc.service` after/requires/wants it. The route service replaces priority `8500` with `to 8.159.128.125/32 lookup main`.
- Verification passed for Axiom toplevel eval, dry-run build, route service unit text, frpc ordering, and route script syntax. Runtime route validation remains deploy/sudo-gated.
- Change review passed with network/security lens applied. The bypass is limited to `8.159.128.125/32` and does not change inbound exposure.
- Generated walkthrough/PR body and wrote Legion wiki task summary plus current FRP/Clash decisions.
