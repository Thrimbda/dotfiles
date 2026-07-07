# acorn-frps-dashboard-nginx

## Metadata

- `task-id`: `acorn-frps-dashboard-nginx`
- `status`: `completed`
- `risk`: `medium`
- `schema-version`: `current`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Outcome Summary

This task exposes the Acorn frps dashboard through nginx at `frps-acorn.0xc1.wang` while keeping the dashboard listener loopback-only on `127.0.0.1:7500`.

The browser-facing auth boundary is nginx Basic Auth using the existing agenix-managed htpasswd secret. Cloudflare DNS has a DNS-only `A` record to `8.159.128.125`; Cloudflare Access is intentionally not configured by this task.

The repo config is validated, but live dashboard behavior still requires a privileged Acorn switch and post-deploy checks.

## Reusable Decisions

- frps dashboard is HTTP and may be exposed through nginx only when bound to loopback.
- TCP `7500` is a dashboard backend port and must not be opened in the NixOS firewall or Aliyun security group.
- Do not put native frps dashboard passwords in Nix config unless a future task adds secret-backed rendering for them.

## Related Raw Sources

- `plan`: `.legion/tasks/acorn-frps-dashboard-nginx/plan.md`
- `log`: `.legion/tasks/acorn-frps-dashboard-nginx/log.md`
- `tasks`: `.legion/tasks/acorn-frps-dashboard-nginx/tasks.md`
- `rfc`: `.legion/tasks/acorn-frps-dashboard-nginx/docs/rfc.md`
- `test-report`: `.legion/tasks/acorn-frps-dashboard-nginx/docs/test-report.md`
- `review`: `.legion/tasks/acorn-frps-dashboard-nginx/docs/review-change.md`
- `report`: `.legion/tasks/acorn-frps-dashboard-nginx/docs/report-walkthrough.md`
