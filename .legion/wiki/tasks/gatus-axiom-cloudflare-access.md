# gatus-axiom-cloudflare-access

## Metadata

- `task-id`: `gatus-axiom-cloudflare-access`
- `status`: `active`
- `risk`: `high`
- `schema-version`: `current`
- `historical`: `false`
- `supersedes`: `gatus-status-page-blackbox-monitoring` public route on `acorn`
- `superseded-by`: `(none)`

## Outcome Summary

This task moves the repo-managed Gatus status page target from `acorn` / `status.0xc1.space` to `axiom` / `status-axiom.0xc1.space`.

Repo-side implementation is complete: `axiom` owns Gatus and Prometheus scrape config, `home-axiom` cloudflared ingress includes the status hostname, and the old `acorn` status nginx module is removed.

Live Cloudflare control-plane work is blocked: the available encrypted API token can read DNS but receives `403` from Zero Trust Access endpoints, and the `axiom` cloudflared credential contains only tunnel runtime fields, so no Access app/policy or DNS route was created.

The current safe rule is to configure and verify Cloudflare Access first, then create the proxied tunnel CNAME. Do not expose `status-axiom.0xc1.space` as DNS-only or tunnel-only without Access.

## Reusable Decisions

- Use `status-axiom.0xc1.space` for the Gatus public hostname; do not use `status.axiom.0xc1.space` or restore `status.0xc1.space` without a new task.
- Treat Cloudflare Access as the auth boundary for the status page; cloudflared only transports traffic to local `127.0.0.1:8080`.
- The Access policy must match `opencode-axiom`: Google IdP plus exact emails `c1@ntnl.io`, `siyuan.arc@gmail.com`, and `froggy2818@gmail.com`, with no broad domain, everyone, bypass, or non-Google allow.
- Do not create DNS/tunnel route for the status hostname until the Access app/policy exists and has been verified.
- `hosts/axiom/secrets/cloudflared-credentials.age` may be decrypted by both the axiom host key and `/home/c1/.ssh/id_ed25519`; it is still only cloudflared tunnel runtime credential material, not an API token.

## Related Raw Sources

- `plan`: `.legion/tasks/gatus-axiom-cloudflare-access/plan.md`
- `log`: `.legion/tasks/gatus-axiom-cloudflare-access/log.md`
- `tasks`: `.legion/tasks/gatus-axiom-cloudflare-access/tasks.md`
- `rfc`: `.legion/tasks/gatus-axiom-cloudflare-access/docs/rfc.md`
- `reviews`: `.legion/tasks/gatus-axiom-cloudflare-access/docs/review-rfc.md`, `.legion/tasks/gatus-axiom-cloudflare-access/docs/review-change.md`
- `verification`: `.legion/tasks/gatus-axiom-cloudflare-access/docs/test-report.md`
- `report`: `.legion/tasks/gatus-axiom-cloudflare-access/docs/report-walkthrough.md`
