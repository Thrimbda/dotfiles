# Axiom FRPC Direct Route

Status: ready for PR

## Summary

Fixes Axiom frpc connectivity to Aliyun Acorn by adding a host-local policy rule that sends `8.159.128.125/32` through the main routing table before Clash/Meta TUN policy routing.

## Current Shape

- `axiom` owns `frpc-aliyun-acorn-direct-route.service`.
- The service installs `priority 8500 to 8.159.128.125/32 lookup main`.
- `frpc.service` requires, wants, and starts after that route service.
- The change is limited to Axiom and does not change generic frp or Clash Verge modules.

## Verification

- Axiom toplevel eval passed.
- Axiom toplevel dry-run build passed.
- Evaluated unit fields show `frpc.service` depends on the route service.
- Evaluated route script passed shell syntax validation.

## Operational Follow-up

- Deploy Axiom.
- Confirm `ip route get 8.159.128.125 uid 1000` no longer uses `dev Meta table 2022`.
- Confirm `frpc.service` remains active and Aliyun Acorn `frps` registers remote listeners on `2225` and `18080`.

## Source Evidence

- Raw task: `.legion/tasks/axiom-frpc-direct-route/`
- RFC: `.legion/tasks/axiom-frpc-direct-route/docs/rfc.md`
- Test report: `.legion/tasks/axiom-frpc-direct-route/docs/test-report.md`
- Change review: `.legion/tasks/axiom-frpc-direct-route/docs/review-change.md`
