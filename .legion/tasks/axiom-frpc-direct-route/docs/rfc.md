# RFC: Axiom FRPC Direct Route

## Decision

Install a host-local policy rule on `axiom` so traffic to `aliyun-acorn` public IP `8.159.128.125/32` uses the `main` routing table before Clash/Meta TUN policy routing.

## Rationale

`frpc` is a critical remote-access/status tunnel and should not depend on desktop proxy routing. The observed route lookup sends `8.159.128.125` via `198.18.0.2 dev Meta table 2022`, and `aliyun-acorn` `frps` shows no incoming traffic while `frpc` reports login EOF/session shutdown. This points to local proxy/TUN interception rather than a remote frps or token problem.

## Implementation Shape

- Add `frpc-aliyun-acorn-direct-route.service` on `axiom`.
- Use a oneshot shell script that replaces priority `8500` with the direct-route rule.
- Rule: `priority 8500 to 8.159.128.125/32 lookup main`.
- Order `frpc.service` after and wants this service.

## Alternatives Rejected

- Change Clash subscription/runtime rules: rejected because it is mutable runtime config and less durable than Nix-owned host policy.
- Run frpc as root: rejected because UID 0 route lookup also goes through Meta in the current rule set.
- Disable Clash Verge TUN globally: rejected because it would break unrelated desktop proxy behavior.
- Change generic frp module: rejected for this first fix because the issue is Axiom-specific interaction with Clash/Meta routing.

## Verification Plan

- Evaluate Axiom toplevel.
- Dry-run build Axiom toplevel.
- Evaluate route service `ExecStart` and `frpc.service` `after`/`wants` fields.
- After deploy, check `ip route get 8.159.128.125 uid 1000` uses the main LAN route, not `dev Meta table 2022`.
- After deploy, check `frpc.service` remains active and `aliyun-acorn` `frps` shows listeners for `2225` and `18080`.
