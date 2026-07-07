# Review RFC

## Verdict

PASS.

## Review

- Scope is clear: create a new `opencode-axiom.0xc1.wang` route and do not replace or alter `opencode-axiom.0xc1.space`.
- Authentication boundary is implementable and conservative: Cloudflare Access protects normal proxied traffic, while nginx Basic Auth protects direct-origin bypass.
- Rollback is clear and does not depend on changing the existing `.space` route.
- Verification is specific enough: targeted Nix evals, toplevel builds, Cloudflare DNS/Access API assertions, and live service checks after deployment.
- The selected frp backend port `18081` avoids existing autossh/frp reservations and is explicitly an nginx-only backend.

## Non-blocking Notes

- Double auth is less convenient, but it is acceptable for a sensitive OpenCode entrypoint and safer than exposing origin with Access only.
- A future task could replace origin Basic Auth with origin firewalling to Cloudflare IP ranges, but that is outside this task.
