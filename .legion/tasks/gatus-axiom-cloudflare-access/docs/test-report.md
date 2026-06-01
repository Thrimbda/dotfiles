# Test Report: Gatus Axiom Cloudflare Access

## Summary

PASS with manual post-deploy smoke checks remaining. Repository configuration and local Nix verification passed. Cloudflare Access and DNS were reconciled after the user provided an Access-capable token in `/home/c1/dotfiles/API_TOKEN.env`: `status-axiom.0xc1.space` now has a self-hosted Access app restricted to Google, an exact-email allow policy for `c1@ntnl.io`, `siyuan.arc@gmail.com`, and `froggy2818@gmail.com`, no broad/bypass policy, and a proxied CNAME to the `home-axiom` tunnel.

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

## Cloudflare Token / Credential Evidence

- Command: verify `/home/c1/dotfiles/API_TOKEN.env` without printing token material.
  - Result: PASS.
  - Evidence: token verification HTTP `200`; zone read HTTP `200`; Access identity providers HTTP `200`; Access apps read HTTP `200`; opencode policy read HTTP `200`.

- Command: decrypt `hosts/axiom/secrets/cloudflared-credentials.age` with the user-provided axiom host key, without printing decrypted content.
  - Result: PASS.
  - Evidence: decrypted JSON keys are `AccountTag`, `Endpoint`, `TunnelID`, and `TunnelSecret`; `TunnelID` matches `bc8b3291-de93-4f7f-807a-23f802ef021f`; no `API_TOKEN`, `CLOUDFLARE_API_TOKEN`, `CF_API_TOKEN`, `token`, or `api_token` field exists.

- Command: re-encrypt `hosts/axiom/secrets/cloudflared-credentials.age` to both the axiom host public key and `/home/c1/.ssh/id_ed25519.pub`, then verify with `/home/c1/.ssh/id_ed25519`.
  - Result: PASS.
  - Evidence: user key decrypts the re-encrypted age file; decrypted JSON remains valid; `TunnelID` still matches; no API token field exists.

## Cloudflare Access Evidence

- Command: read current `opencode-axiom.0xc1.space` Access app/policy and Google IdP.
  - Result: PASS.
  - Evidence: Google IdP is `399adc69-d770-4685-8acf-cdea3acca230`; opencode app is `d4fbde13-f314-43e8-9cc8-6243935569c6`, `self_hosted`, Google-only, `auto_redirect_to_identity = true`, `session_duration = 24h`; opencode allow policy includes exact emails `c1@ntnl.io`, `siyuan.arc@gmail.com`, and `froggy2818@gmail.com` and requires Google login.

- Command: create `status-axiom.0xc1.space` self-hosted Access app.
  - Result: PASS.
  - Evidence: created app `c73a8ab9-990b-41f2-bc03-41370769a69b`, name `status-axiom`, domain `status-axiom.0xc1.space`, type `self_hosted`, `allowed_idps = [399adc69-d770-4685-8acf-cdea3acca230]`, `auto_redirect_to_identity = true`, `session_duration = 24h`.

- Command: create `status-axiom.0xc1.space` allow policy.
  - Result: PASS.
  - Evidence: created policy `e20cae5a-a2de-4877-9fa0-285210ca76d1`, name `allow-c1-siyuan-froggy-google`, decision `allow`, precedence `1`, include exact emails `c1@ntnl.io`, `siyuan.arc@gmail.com`, and `froggy2818@gmail.com`, require Google login method `399adc69-d770-4685-8acf-cdea3acca230`, exclude empty.

- Command: assert final `status-axiom.0xc1.space` Access policy state.
  - Result: PASS.
  - Evidence: exactly one Access app exists for `status-axiom.0xc1.space`; app type/domain/IdP/auto-redirect shape is correct; exactly one allow policy has the required exact emails and Google requirement; broad/bypass policy count is `0`.

## Cloudflare DNS Evidence

- Command: create DNS record only after Access verification.
  - Result: PASS.
  - Evidence: created proxied CNAME `status-axiom.0xc1.space -> bc8b3291-de93-4f7f-807a-23f802ef021f.cfargotunnel.com`, record id `c7c261f01c4deeb89258b2d3941bb3a5`.

- Command: read DNS records for old `status.0xc1.space`.
  - Result: PASS.
  - Evidence: no DNS records existed for `status.0xc1.space` during verification.

## Safety Decisions

- Created DNS only after Access app/policy assertions passed.
- Did not print or persist decrypted token material, tunnel credential JSON, `TunnelSecret`, or OIDC secret values.
- Did not run production `nixos-rebuild switch`.

## Manual Post-Deploy Checks

- Deploy `axiom`.
- Check `systemctl status gatus cloudflared prometheus`.
- Confirm allowed Google login succeeds for the exact-email allowlist.
- Confirm an unlisted Google account is denied.
- Confirm Prometheus can scrape Gatus metrics.

## Final Status

Repo changes and Cloudflare Access/DNS reconciliation are complete. Production deployment and interactive browser smoke checks remain manual.
