## Summary

- Move repo-managed Gatus from `acorn` to `axiom` and expose it through the existing `home-axiom` cloudflared ingress at `status-axiom.0xc1.space`.
- Remove the old `acorn` `status.0xc1.space` nginx/ACME status-page entrypoint and update the Gatus runbook.
- Record verification evidence and the current Cloudflare Access credential blocker.

## Verification

- `nix build .#nixosConfigurations.axiom.config.system.build.toplevel --no-link`
- Targeted Nix evals for Gatus loopback binding, metrics, cloudflared ingress, Prometheus scrape, and old `acorn` vhost absence
- `git diff --check`
- Cloudflare DNS read-only checks for `status-axiom.0xc1.space`, `opencode-axiom.0xc1.space`, and `status.0xc1.space`

## Blocker

Live Cloudflare Access app/policy reconciliation is blocked because the available encrypted Cloudflare token receives `403` from Zero Trust Access endpoints, and the user-authorized local `token.env` file is absent. The DNS route was intentionally not created without verified Access protection.

## Manual Follow-Up

- Provide an Access-capable Cloudflare token or configure the Access app/policy manually.
- Create/verify the exact-email Google Access policy for `status-axiom.0xc1.space` before creating the proxied tunnel CNAME.
- Deploy `axiom` and smoke `gatus`, `cloudflared`, `prometheus`, allowed Google login, denied unlisted login, and Prometheus scrape.
