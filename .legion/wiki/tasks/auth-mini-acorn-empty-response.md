# Auth Mini Acorn Empty Response Hotfix

## Metadata

- `task-id`: `auth-mini-acorn-empty-response`
- `status`: `ready for PR`
- `risk`: `low`
- `schema-version`: `current`
- `historical`: `false`
- `supersedes`: `post-switch DNS/setup gap from auth-mini-acorn-gateway`
- `superseded-by`: `(none)`

## Outcome Summary

This task diagnosed the post-switch `NS_ERROR_NET_EMPTY_RESPONSE` for `auth.0xc1.wang`. Acorn's `auth-mini.service` was healthy and the UI returned `200` at `/web/` when traffic reached Acorn. The empty response came from missing Cloudflare DNS records for `auth.0xc1.wang` and `auth-gateway.0xc1.wang`, which caused client/proxy DNS to resolve to `198.18.x.x` fake-ip addresses instead of Acorn.

The missing Cloudflare DNS-only A records were created live, both pointing at `8.159.128.125`. The repo hotfix adds an nginx exact-root redirect so `https://auth.0xc1.wang/` redirects to `/web/` instead of returning auth-mini's API `404`.

## Reusable Decisions

- For `auth-mini`, treat `/web/` as the browser UI path. Public root `/` should redirect to `/web/` for operator/browser usability.
- For new Acorn public `0xc1.wang` hostnames, Cloudflare DNS records are a required release artifact. ACME issuance and local service health are not enough to prove browser reachability.
- Use DNS-only A records to `8.159.128.125` for `auth.0xc1.wang` and `auth-gateway.0xc1.wang`, matching the direct-origin Acorn gateway model.

## Validation

- Live Acorn diagnostics showed `auth-mini.service` active and listening on `127.0.0.1:7777`.
- Loopback `GET /web/` returned `200 OK` auth-mini HTML; loopback `GET /` returned JSON `404` before this hotfix.
- Direct HTTPS/SNI to `8.159.128.125` for `https://auth.0xc1.wang/web/` returned `HTTP/2 200` auth-mini HTML.
- Cloudflare DoH returned `auth.0xc1.wang A 8.159.128.125` and `auth-gateway.0xc1.wang A 8.159.128.125` after the live DNS fix.
- `acorn` toplevel build passed with the root redirect.
- Generated nginx config contains `location = / { return 302 /web/; }`.
- `git diff --check` passed.

## Operational Follow-Up

- Switch Acorn after the PR merges, then confirm `curl -I https://auth.0xc1.wang/` returns `302 Location: /web/` and `curl -fsS https://auth.0xc1.wang/web/ >/dev/null` succeeds.
- If a browser still resolves `auth.0xc1.wang` to `198.18.x.x`, refresh the browser/proxy DNS cache; Cloudflare DoH already reports the correct A records.
- Continue the original auth-mini bootstrap/login smoke: configure issuer/RP/admin state and test allowed/denied users plus protected Opencode WebSocket behavior.

## Related Raw Sources

- `plan`: `.legion/tasks/auth-mini-acorn-empty-response/plan.md`
- `log`: `.legion/tasks/auth-mini-acorn-empty-response/log.md`
- `tasks`: `.legion/tasks/auth-mini-acorn-empty-response/tasks.md`
- `test-report`: `.legion/tasks/auth-mini-acorn-empty-response/docs/test-report.md`
- `change-review`: `.legion/tasks/auth-mini-acorn-empty-response/docs/review-change.md`
- `walkthrough`: `.legion/tasks/auth-mini-acorn-empty-response/docs/report-walkthrough.md`
- `pr-body`: `.legion/tasks/auth-mini-acorn-empty-response/docs/pr-body.md`
