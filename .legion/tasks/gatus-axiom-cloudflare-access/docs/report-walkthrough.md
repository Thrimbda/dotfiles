# Walkthrough: Gatus Axiom Cloudflare Access

> **Mode**: implementation  
> **Status**: BLOCKED on live Cloudflare Access credential

## What Changed

- Moved repo-managed Gatus enablement from `acorn` to `axiom`.
- Added `status-axiom.0xc1.space -> http://127.0.0.1:8080` to the existing `home-axiom` cloudflared ingress while preserving `opencode-axiom.0xc1.space -> http://127.0.0.1:4096`.
- Removed the old repo-managed `acorn` status-page nginx/ACME entrypoint for `status.0xc1.space`.
- Updated the Gatus runbook to describe `axiom`, cloudflared transport, and Cloudflare Access as the auth boundary.

## Verification

- PASS: `nix build .#nixosConfigurations.axiom.config.system.build.toplevel --no-link`.
- PASS: targeted evals proved Gatus loopback binding, metrics enabled, status cloudflared ingress, Prometheus scrape target, and old `acorn` vhost absence.
- PASS: `git diff --check`.
- PASS: DNS read-only checks proved `status-axiom.0xc1.space` currently has no record, `opencode-axiom.0xc1.space` points at the `home-axiom` tunnel, and `status.0xc1.space` has no record.
- PASS: `axiom` cloudflared credential was decrypted with the provided host key, confirmed to contain no API token, and re-encrypted to both the host key and `/home/c1/.ssh/id_ed25519.pub`.
- BLOCKED: Cloudflare Access API calls return `403` with the available encrypted API token, and the user-authorized local `token.env` file is absent.

## Security Notes

- Cloudflare Access is the authentication boundary; cloudflared ingress is only transport.
- The `axiom` cloudflared credential is tunnel runtime material, not a Zero Trust Access API token.
- No DNS route was created because Access app/policy could not be configured or verified first.
- No plaintext API token, tunnel credential JSON, `TunnelSecret`, or OIDC secret was printed or committed.

## Required Follow-Up

- Provide an Access-capable Cloudflare token or perform the equivalent dashboard/API steps manually.
- Create/verify the `status-axiom.0xc1.space` self-hosted Access app with Google IdP and exact emails `c1@ntnl.io`, `siyuan.arc@gmail.com`, and `froggy2818@gmail.com`.
- After Access verification, create the proxied CNAME `status-axiom.0xc1.space -> bc8b3291-de93-4f7f-807a-23f802ef021f.cfargotunnel.com`.
- Deploy `axiom` and run post-deploy service/login/Prometheus smoke checks.

## Evidence

- Contract: `.legion/tasks/gatus-axiom-cloudflare-access/plan.md`
- Design: `.legion/tasks/gatus-axiom-cloudflare-access/docs/rfc.md`
- RFC review: `.legion/tasks/gatus-axiom-cloudflare-access/docs/review-rfc.md`
- Verification: `.legion/tasks/gatus-axiom-cloudflare-access/docs/test-report.md`
- Change review: `.legion/tasks/gatus-axiom-cloudflare-access/docs/review-change.md`
