# Log

- User reported that after switching Acorn, `auth.0xc1.wang` shows browser `NS_ERROR_NET_EMPTY_RESPONSE`.
- Initial hypothesis: nginx/TLS reaches the host, but the auth-mini upstream on `127.0.0.1:7777` is closing, crashing, or otherwise not serving HTTP.
- Worktree envelope opened at `.worktrees/auth-mini-acorn-empty-response` on branch `legion/auth-mini-acorn-empty-response-fix` from `origin/master`.
- Live diagnostics disproved service crash: `auth-mini.service` is active, loopback `GET /web/` returns 200 HTML, and direct HTTPS to Acorn IP with SNI returns the auth-mini page.
- Root cause for the browser empty response was missing Cloudflare DNS records: `auth.0xc1.wang` and `auth-gateway.0xc1.wang` had no A records, while the local resolver produced `198.18.x.x` fake-ip addresses.
- Created DNS-only Cloudflare A records for `auth.0xc1.wang` and `auth-gateway.0xc1.wang` pointing to `8.159.128.125` using the existing Cloudflare DNS token.
- Implemented repo hotfix so nginx redirects exact `https://auth.0xc1.wang/` to `/web/`; the live service currently serves the UI at `/web/` and returns API 404 at `/` until the hotfix is switched.
