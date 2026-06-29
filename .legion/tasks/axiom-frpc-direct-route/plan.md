# Axiom FRPC Direct Route

## Goal

Make `axiom` `frpc.service` connect directly to `aliyun-acorn` `frps` at `8.159.128.125:7000` instead of being captured by the local Clash Verge / Meta TUN policy route.

## Problem

After the `0xc1.wang` status entry was deployed, `frpc.service` on `axiom` repeatedly failed with `login to the server failed: EOF` / `session shutdown`. `aliyun-acorn` `frps.service` was active and listening on `*:7000`, but frps logs and service IP accounting did not show incoming client traffic. On `axiom`, `ip route get 8.159.128.125 uid 1000` routes through `198.18.0.2 dev Meta table 2022`, so the frpc connection is being sent through the local Clash/Meta TUN path.

## Acceptance

- `axiom` installs a policy rule that routes `8.159.128.125/32` through the normal `main` routing table before Clash/Meta rules run.
- `frpc.service` starts after and wants the route service.
- The route service is host-local to `axiom`; it does not change global Clash Verge module behavior.
- No frp token, Basic Auth credential, or Aliyun secret is printed or committed.
- Nix evaluation and dry-run build pass for `axiom`.
- Evaluated systemd units show `frpc.service` ordered after the route service.

## Scope

- Update `hosts/axiom/default.nix` with a host-local systemd oneshot route service and frpc ordering.
- Add Legion task evidence, verification, review, walkthrough, and wiki writeback.

## Non-goals

- Do not change `modules/services/frp.nix` unless host-local ordering cannot solve the issue.
- Do not disable Clash Verge / Meta TUN globally.
- Do not change proxy subscription rules or runtime Clash YAML.
- Do not open `18080` publicly.
- Do not change Aliyun security-group state in dotfiles.

## Assumptions

- `aliyun-acorn` public IP remains `8.159.128.125`.
- Clash/Meta policy rules currently run at priorities around `9001/9002`, so priority `8500` wins.
- The main table default route is the intended direct LAN egress for reaching Aliyun Acorn.

## Risks

- Route priority must remain below Clash/Meta priorities; if Clash changes its rule priorities, validation must catch it.
- The rule is destination-wide for `8.159.128.125`, not only TCP `7000`; that is intentional so SSH/frp management to Acorn also bypasses the proxy consistently.
- Local runtime validation needs deployment or sudo to install policy rules; unprivileged local checks can only verify evaluated config.

## Design Summary

Add an Axiom-local oneshot systemd service, `frpc-aliyun-acorn-direct-route.service`, that replaces priority `8500` with:

- `ip rule add priority 8500 to 8.159.128.125/32 lookup main` when the rule is missing.

The service runs after `network-online.target`, before `frpc.service`, and is required/wanted by `frpc.service` so the direct route is installed before frpc dials `frps` during normal service start and boot activation.

## Phases

1. Materialize task contract and design evidence.
2. Implement host-local route service and frpc ordering.
3. Verify Nix eval/dry-run and evaluated systemd unit fields.
4. Review security/scope impact.
5. Produce walkthrough, wiki writeback, PR, and follow PR lifecycle.
