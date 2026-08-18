# Deploy Legion Pi Web via Acorn FRP

## Metadata

- `task-id`: `deploy-legion-pi-web-frp`
- `status`: `deployed; verification and security review passed; closing lifecycle in progress`
- `risk`: `high`
- `schema-version`: `current`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Current Truth

- Axiom user `c1` owns Legion Pi core `0.84.2` at `/home/c1/.local/share/legion-pi/profile` and PI WEB `1.202608.1` under `/home/c1/.local`. Nix owns the login-shell environment and `Linger=yes`; upstream `pi-web install` owns `pi-web.service` and `pi-web-sessiond.service`, with writable config at `/home/c1/.config/pi-web/config.json` and data under `/home/c1/.local/share/legion-pi/pi-web`.
- The authenticated path is browser `:443` -> Acorn nginx -> Acorn FRPS remote TCP `18082` -> Axiom `frpc` proxy `axiom-pi-web-http` -> Auth Mini gateway `127.0.0.1:7782` -> PI WEB `127.0.0.1:8504`. The FRP runtime is `0.66.0`, and FRP maps the gateway rather than PI WEB.
- Axiom keeps `7782` and `8504` loopback-only and outside its firewall. Acorn's shared FRPS makes `18082` wildcard-bound, but the port remains outside the host firewall, is protected by a Nix assertion, and is consumed only by nginx through `127.0.0.1:18082`.
- The DNS-only `pi-axiom.0xc1.wang` A record points to Acorn at `8.159.128.125`. Acorn nginx terminates public HTTPS with a Cloudflare DNS ACME certificate and preserves WebSocket upgrades, unbuffered streaming, and 24-hour long-connection timeouts.
- The PI vhost permits WebSocket upgrade only for the exact semantic Origin `https://pi-axiom.0xc1.wang`; sibling, foreign, suffixed, and missing Origin requests fail closed with `403` before FRP/Auth Mini/PI WEB. Ordinary PI HTTP/API traffic and other vhosts do not consume this guard.

## Deployment And Verification

- Axiom was activated first; Acorn was built, transferred, and activated from Axiom with the mandated remote deployment command. No build ran on Acorn.
- Pi install was idempotent and `verify` returned `READY`. PI WEB `doctor`, `status`, and `version` passed; both user units were active with zero restarts, `8504/7782` were loopback-only, all four FRP proxies started, and public `18082` remained closed while `443` was reachable.
- Public TLS/SNI, DNS, unauthenticated Auth Mini redirect, ordinary HTTP/API, exact/foreign/missing-Origin WebSocket behavior, and status/OpenCode/Auth Mini/FRP/1Ex regressions passed. The authenticated PI page, session stream, and terminal gate also passed using operator-supplied browser evidence.
- Final independent verification and security review returned **PASS** on 2026-08-19 with no unresolved blocker. The authenticated browser result and active Acorn generation identity remain disclosed operator/deployment-supplied evidence.

## Rollback And Accepted Residuals

- Runtime rollback is `pi-web uninstall`, which removes the upstream user units while retaining profile/config/data for diagnosis. Axiom rollback selects the prior Nix generation; Acorn rollback removes this task's certificate, vhost, Origin guard, and firewall assertion, then redeploys only from Axiom with the prescribed command. Either host rollback breaks the public chain closed.
- PI WEB intentionally retains `c1` terminal/agent authority behind Auth Mini. Established WebSockets are not revoked by later logout or session expiry and must be disconnected during suspected session compromise.
- FRP transport is encrypted and token-authenticated but does not verify frps certificate identity; active MITM remains accepted, pre-existing debt outside this task's threat model.
- PI WEB, `node-pty`, and the upstream user units are persistent but imperative rather than Nix-reproducible. Final verification did not exercise a disruptive logout, restart, reboot, or rollback.

## Reusable Decisions

- See [Cookie-Authenticated WebSocket Edge Guard](../patterns.md#cookie-authenticated-websocket-edge-guard) for the promoted exact-Origin and sentinel-Cookie verification pattern.

## Related Raw Sources

- `plan`: [`.legion/tasks/deploy-legion-pi-web-frp/plan.md`](../../tasks/deploy-legion-pi-web-frp/plan.md)
- `log`: [`.legion/tasks/deploy-legion-pi-web-frp/log.md`](../../tasks/deploy-legion-pi-web-frp/log.md)
- `tasks`: [`.legion/tasks/deploy-legion-pi-web-frp/tasks.md`](../../tasks/deploy-legion-pi-web-frp/tasks.md)
- `rfc`: [`.legion/tasks/deploy-legion-pi-web-frp/docs/rfc.md`](../../tasks/deploy-legion-pi-web-frp/docs/rfc.md)
- `rfc-review`: [`.legion/tasks/deploy-legion-pi-web-frp/docs/review-rfc.md`](../../tasks/deploy-legion-pi-web-frp/docs/review-rfc.md)
- `test-report`: [`.legion/tasks/deploy-legion-pi-web-frp/docs/test-report.md`](../../tasks/deploy-legion-pi-web-frp/docs/test-report.md)
- `change-review`: [`.legion/tasks/deploy-legion-pi-web-frp/docs/review-change.md`](../../tasks/deploy-legion-pi-web-frp/docs/review-change.md)
- `report`: [`.legion/tasks/deploy-legion-pi-web-frp/docs/report-walkthrough.md`](../../tasks/deploy-legion-pi-web-frp/docs/report-walkthrough.md)
