# Auth Mini Node Gateway Migration

## Metadata

- `task-id`: `auth-mini-node-gateway-migration`
- `status`: `ready for PR; verification and readiness review passed; no live deployment`
- `risk`: `high`
- `schema-version`: `current`
- `historical`: `false`
- `supersedes`: `Acorn-local status/OpenCode gateway placement from auth-mini-acorn-gateway; auth-mini-gateway-latest-pin`
- `superseded-by`: `(none)`

## Outcome Summary

The repository topology moves status and OpenCode authentication enforcement and reverse proxying onto Axiom. Dedicated proxy-mode gateways bind `127.0.0.1:7779/7780` ahead of Gatus `8080` and OpenCode `4096`, and FRP targets the gateway listeners instead of the application ports.

Acorn remains the public TLS/nginx, auth-mini, and FRP ingress host. It keeps the local `auth-gateway` and `frps-acorn` gateway instances, while the status and OpenCode vhosts forward to FRP remote ports `18080/18081` without a second Acorn-local auth gateway.

No live deployment or cutover test was performed. Fresh Axiom gateway state and a new cookie secret will reset existing status/OpenCode gateway sessions at cutover.

## Reusable Decisions

- For Acorn-published Axiom services, place the service-specific gateway on Axiom before the loopback application and make FRP target the gateway port, not the application port.
- Keep the application, gateway, and FRP backend ports loopback/private and absent from host firewalls; only Acorn nginx terminates public HTTPS.
- Keep one same-origin gateway instance per protected hostname, with host-local agenix secrets and separate state. With no trusted proxy CIDRs, applications see the loopback FRP peer rather than the original client IP.

## Validation

- The pinned gateway package and Axiom toplevel build passed without activation.
- Targeted evaluation proved gateway/upstream ports, FRP targets, Acorn retained services, nginx backends, firewall exclusions, secret metadata, and service hardening.
- `git diff --check` and the scoped security/readiness review passed with no blocking findings or public auth bypass.

## Related Raw Sources

- `plan`: `.legion/tasks/auth-mini-node-gateway-migration/plan.md`
- `log`: `.legion/tasks/auth-mini-node-gateway-migration/log.md`
- `tasks`: `.legion/tasks/auth-mini-node-gateway-migration/tasks.md`
- `implementation-note`: `.legion/tasks/auth-mini-node-gateway-migration/docs/implementation-note.md`
- `test-report`: `.legion/tasks/auth-mini-node-gateway-migration/docs/test-report.md`
- `change-review`: `.legion/tasks/auth-mini-node-gateway-migration/docs/review-change.md`
- `report`: `.legion/tasks/auth-mini-node-gateway-migration/docs/report-walkthrough.md`
