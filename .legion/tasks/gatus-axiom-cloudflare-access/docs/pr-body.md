## Summary

- Move repo-managed Gatus from `acorn` to `axiom` and expose it through the existing `home-axiom` cloudflared ingress at `status-axiom.0xc1.space`.
- Remove the old `acorn` `status.0xc1.space` nginx/ACME status-page entrypoint and update the Gatus runbook.
- Record verification evidence for repo config, Cloudflare Access, DNS, and secret hygiene.

## Verification

- `nix build .#nixosConfigurations.axiom.config.system.build.toplevel --no-link`
- Targeted Nix evals for Gatus loopback binding, metrics, cloudflared ingress, Prometheus scrape, and old `acorn` vhost absence
- `git diff --check`
- Cloudflare Access app/policy assertions for `status-axiom.0xc1.space`
- Proxied CNAME creation for `status-axiom.0xc1.space -> bc8b3291-de93-4f7f-807a-23f802ef021f.cfargotunnel.com`
- Axiom cloudflared credential inspection with the provided host key; no API token field found; re-encrypted to host key plus `/home/c1/.ssh/id_ed25519.pub`

## Manual Follow-Up

- Deploy `axiom`.
- Smoke `gatus`, `cloudflared`, `prometheus`, allowed Google login, denied unlisted login, and Prometheus scrape.

## Security Notes

- Cloudflare Access was configured before DNS was created.
- No broad domain/everyone/bypass policy was added.
- No plaintext token or tunnel credential JSON is committed.
