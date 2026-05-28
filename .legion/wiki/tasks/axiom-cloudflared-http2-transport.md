# Axiom Cloudflared HTTP2 Transport Fix

## Metadata

- `task-id`: `axiom-cloudflared-http2-transport`
- `status`: `active`
- `risk`: `low`
- `schema-version`: `2026-05-08-legion-workflow`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Outcome Summary

This task pins the `axiom` cloudflared connector for `opencode-axiom.0xc1.space` to HTTP/2 transport after live debugging showed the default QUIC path timing out through the current Clash/Meta fake-ip route.

The durable repository truth is now `protocol = "http2"` in `hosts/axiom/default.nix` under the existing axiom cloudflared `extraConfig`. Tunnel id, credentials, hostname, ingress origin, opencode service, and Cloudflare Access policy remain unchanged.

Targeted validation passed for the generated `/etc/cloudflared/config.yml`, the cloudflared systemd `ExecStart`, and an axiom toplevel dry-run. Runtime deployment and service restart remain operational follow-up because the session did not have passwordless sudo.

## Reusable Decisions

- On `axiom`, the opencode cloudflared connector should use HTTP/2 transport while the current Clash/Meta fake-ip network path causes QUIC/UDP edge dial timeouts.
- Prefer host-level cloudflared `extraConfig` for connector transport overrides so the existing module continues to own `/etc/cloudflared/config.yml` declaratively.
- Do not treat a temporary user-level cloudflared connector as durable service state; stop it after the NixOS system service is deployed and healthy.

## Related Raw Sources

- `plan`: `.legion/tasks/axiom-cloudflared-http2-transport/plan.md`
- `log`: `.legion/tasks/axiom-cloudflared-http2-transport/log.md`
- `tasks`: `.legion/tasks/axiom-cloudflared-http2-transport/tasks.md`
- `rfc`: `.legion/tasks/axiom-cloudflared-http2-transport/docs/rfc.md`
- `test-report`: `.legion/tasks/axiom-cloudflared-http2-transport/docs/test-report.md`
- `change-review`: `.legion/tasks/axiom-cloudflared-http2-transport/docs/review-change.md`
- `report`: `.legion/tasks/axiom-cloudflared-http2-transport/docs/report-walkthrough.md`
