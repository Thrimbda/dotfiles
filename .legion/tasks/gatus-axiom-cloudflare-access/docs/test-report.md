# Test Report: Gatus Axiom Cloudflare Access

## Summary

BLOCKED on live Cloudflare Access control-plane credentials. Repository configuration and local Nix verification passed, and Cloudflare DNS read-only checks confirmed there is no current `status-axiom.0xc1.space` DNS record. The available encrypted Cloudflare API token can read the `0xc1.space` zone but receives `403` from Zero Trust Access endpoints, so the Access application/policy could not be created or verified. No DNS/tunnel route was created because doing so without Access verification could create an unauthenticated public surface after deployment.

## Repo Verification

- Command: `nix build .#nixosConfigurations.axiom.config.system.build.toplevel --no-link`
  - Result: PASS.
  - Evidence: axiom NixOS toplevel built successfully.

- Command: `nix eval --option eval-cache false .#nixosConfigurations.axiom.config.services.gatus.settings.metrics`
  - Result: PASS.
  - Evidence: `true`.

- Command: evaluate `.#nixosConfigurations.axiom.config.services.gatus.settings.web.address`
  - Result: PASS.
  - Evidence: `"127.0.0.1"`.

- Command: evaluate `.#nixosConfigurations.axiom.config.modules.services.cloudflared.extraConfig.ingress --json`
  - Result: PASS.
  - Evidence: ingress contains `opencode-axiom.0xc1.space -> http://127.0.0.1:4096`, `status-axiom.0xc1.space -> http://127.0.0.1:8080`, then `http_status:404`.

- Command: evaluate `.#nixosConfigurations.axiom.config.services.prometheus.scrapeConfigs --json`
  - Result: PASS.
  - Evidence: scrape job `gatus` targets `127.0.0.1:8080` with `metrics_path = /metrics` and `scrape_interval = 30s`.

- Command: expression eval for `acorn` old vhost absence.
  - Result: PASS.
  - Evidence: `services.nginx.virtualHosts ? "status.0xc1.space"` returned `false`.

- Command: `git diff --check`
  - Result: PASS.
  - Evidence: no whitespace errors.

## Cloudflare DNS Evidence

- Command: read DNS records for `status-axiom.0xc1.space` with the canonical encrypted Cloudflare API token.
  - Result: PASS.
  - Evidence: no DNS records currently exist for `status-axiom.0xc1.space`.

- Command: read DNS records for `opencode-axiom.0xc1.space` with the canonical encrypted Cloudflare API token.
  - Result: PASS.
  - Evidence: proxied CNAME points to `bc8b3291-de93-4f7f-807a-23f802ef021f.cfargotunnel.com`.

- Command: read DNS records for old `status.0xc1.space` with the canonical encrypted Cloudflare API token.
  - Result: PASS.
  - Evidence: no DNS records currently exist for `status.0xc1.space`.

## Cloudflare Access Evidence

- Command: `GET /accounts/<account-id>/access/identity_providers` with `hosts/charlie/secrets/cloudflare-api-token.age` decrypted in-process.
  - Result: BLOCKED.
  - Evidence: Cloudflare returned `403`.

- Command: source `/home/c1/dotfiles/token.env` after user authorization.
  - Result: BLOCKED.
  - Evidence: file did not exist in the current filesystem state; no `API_TOKEN`, `CLOUDFLARE_API_TOKEN`, or `CF_API_TOKEN` environment variable was present.

- Command: inspect `axiom` cloudflared credential availability without printing decrypted content.
  - Result: BLOCKED.
  - Evidence: current user key does not match the age recipients; non-interactive `sudo` for `/etc/ssh/ssh_host_ed25519_key` requires a password. Also, cloudflared runtime credential JSON is not a Cloudflare Zero Trust Access API token and cannot create Access apps/policies.

## Safety Decisions

- Did not create the `status-axiom.0xc1.space` DNS CNAME route because the required Cloudflare Access app/policy could not be configured or verified first.
- Did not print or persist decrypted token material, tunnel credential JSON, `TunnelSecret`, or OIDC secret values.
- Did not run production `nixos-rebuild switch`.

## Required Manual / Resume Steps

When an Access-capable Cloudflare token is available, perform these in order:

1. Verify the current Google identity provider and current `opencode-axiom.0xc1.space` Access app/policy state.
2. Create or reconcile exactly one self-hosted Access app for `status-axiom.0xc1.space`.
3. Restrict the app to the Google IdP, with `auto_redirect_to_identity = true` and session duration aligned with `opencode-axiom`.
4. Create or update one allow policy with exact emails `c1@ntnl.io`, `siyuan.arc@gmail.com`, and `froggy2818@gmail.com`, requiring the Google login method.
5. Verify there are no broad domain, everyone, group, service-token, bypass, or non-Google allow policies.
6. Only after Access verification, create the proxied CNAME `status-axiom.0xc1.space -> bc8b3291-de93-4f7f-807a-23f802ef021f.cfargotunnel.com`.
7. Deploy `axiom`, then manually smoke `systemctl status gatus cloudflared prometheus`, allowed Google login, denied unlisted Google login, and Prometheus scrape visibility.

## Final Status

Repo changes are ready for review. Live Cloudflare Access/DNS reconciliation remains blocked on an Access-capable credential.
