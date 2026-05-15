# RFC: Gatus Status Page Blackbox Monitoring

> **Profile**: Standard RFC  
> **Status**: Draft  
> **Owners**: agent/user  
> **Created**: 2026-05-15  
> **Last Updated**: 2026-05-15

## Context

Linear 0XC-7 asks for Gatus as the first status page and black-box monitoring entrypoint. The repository is a NixOS flake/dotfiles repo with host-level configuration, a small `modules.services.prometheus` wrapper, nginx service defaults, Cloudflare Tunnel usage for selected hosts, and an `acorn` server host that already exposes `vault.0xc1.space` through nginx/ACME.

The first version should make endpoint health config reviewable in Git while preserving the boundary from the Linear issue:

- Gatus monitors external/user-visible availability and publishes a status page.
- Prometheus remains the white-box metrics system.
- Gatus exposes `/metrics` so Prometheus can scrape Gatus result metrics.
- Incident workflow and external notification channels are deferred.

## Goals

- Add a reusable NixOS Gatus wrapper under `modules.services.gatus`.
- Enable a first Gatus deployment on `acorn` with sqlite storage, loopback service binding, nginx reverse proxy, and metrics enabled.
- Define at least 3 initial endpoints covering public HTTP, TLS certificate expiry, and service self-check or public tunnel availability.
- Provide Prometheus scrape configuration shape for Gatus metrics.
- Add a runbook that explains endpoint changes, local validation, status page access, PromQL/Grafana entrypoints, and Gatus failure handling.

## Non-goals

- Do not replace Prometheus white-box monitoring with Gatus.
- Do not introduce Docker Compose or Kubernetes for the first repo-native deployment.
- Do not implement Slack/Discord/Telegram/Email/PagerDuty alerting in this task.
- Do not expose internal-only service details on a public status page.
- Do not run a production `nixos-rebuild switch` from this task.

## Options

### Option A: NixOS Gatus Module on `acorn` (Chosen)

Add a repo wrapper around `services.gatus`, enable it in `hosts/acorn`, proxy `status.0xc1.space` through nginx, persist sqlite data under `/var/lib/gatus`, and define endpoints in Nix.

Pros:

- Matches the repo's NixOS host/module architecture.
- Keeps endpoint inventory in code review.
- Reuses existing nginx/ACME patterns on `acorn`.
- Makes Prometheus scrape config composable with the existing Prometheus wrapper.

Cons:

- Requires current nixpkgs to expose `services.gatus` options.
- Host build is the main validation surface; runtime DNS/ACME still needs manual confirmation.
- Less portable than Docker Compose outside this repo.

### Option B: Docker Compose under `infra/status`

Add `infra/status/docker-compose.yml`, `config.yaml`, Prometheus scrape example, and README, then deploy manually.

Pros:

- Closest to the Linear issue's suggested quick-start layout.
- Easy to run outside NixOS.
- Upstream Gatus examples map directly to YAML.

Cons:

- Introduces a second deployment style into a NixOS-first repo.
- Duplicates nginx/reverse proxy and persistence decisions outside host config.
- Harder to evaluate with existing flake checks.

### Option C: Module Only, No Host Enablement

Add `modules.services.gatus` but leave all host enablement and endpoint inventory for a later task.

Pros:

- Lowest runtime risk.
- Useful as a reusable foundation.

Cons:

- Does not satisfy Linear's requirement for a runnable Gatus instance.
- Does not validate real endpoint inventory, nginx proxying, or Prometheus scrape shape.

## Decision

Choose Option A: add a NixOS-first Gatus module and enable it on `acorn`.

Rationale:

- The repository already models services through `modules/services/*.nix` and host-specific enablement.
- `acorn` is the only observed server host with public nginx/ACME service configuration in scope.
- Config-as-code endpoint inventory is the main reason to prefer Gatus over UI-first alternatives.
- Docker Compose can remain a documented alternative, but the first implementation should not split deployment styles.

## Proposed Design

### Module Boundary

Add `modules/services/gatus.nix` with a minimal wrapper:

- `modules.services.gatus.enable`: enables Gatus on Linux.
- `modules.services.gatus.port`: default `8080`.
- `modules.services.gatus.domain`: default `null`; when set, create nginx vhost reverse proxy to loopback.
- `modules.services.gatus.endpoints`: list of Gatus endpoint attrsets.
- `modules.services.gatus.extraSettings`: attrset merged into upstream `services.gatus.settings` for future extension.
- `modules.services.gatus.prometheusScrape.enable`: default `false`; when enabled and `modules.services.prometheus.enable = true`, add a scrape job for `127.0.0.1:<port>`.

The wrapper should set these defaults:

- `services.gatus.enable = true`
- `services.gatus.settings.metrics = true`
- `services.gatus.settings.storage.type = "sqlite"`
- `services.gatus.settings.storage.path = "/var/lib/gatus/gatus.db"`
- `services.gatus.settings.storage.maximum-number-of-results = 1000`
- `services.gatus.settings.storage.maximum-number-of-events = 100`
- `services.gatus.settings.web.address = "127.0.0.1"`
- `services.gatus.settings.web.port = cfg.port`
- `services.gatus.settings.endpoints = cfg.endpoints`

Gatus should bind only through loopback (`web.address = "127.0.0.1"`); public access goes through nginx, and the Gatus port should not be opened in the firewall.

### `acorn` Host Enablement

Add `hosts/acorn/modules/status.nix` and import it from `hosts/acorn/default.nix`. This keeps status-page configuration near the existing `vaultwarden.nix` host module.

Initial host settings:

- `modules.services.prometheus.enable = true`
- `modules.services.gatus.enable = true`
- `modules.services.gatus.domain = "status.0xc1.space"`
- `modules.services.gatus.prometheusScrape.enable = true`
- `modules.services.gatus.endpoints = [...]`

Initial endpoint inventory should prefer public-safe targets:

- `vaultwarden-web`: `https://vault.0xc1.space`, group `public`, conditions `[STATUS] == 200`, `[CERTIFICATE_EXPIRATION] > 336h`, `[RESPONSE_TIME] < 2000`.
- `status-page`: `http://127.0.0.1:<port>`, group `infra`, conditions `[STATUS] == 200`, `[RESPONSE_TIME] < 500`.
- `opencode-axiom`: `https://opencode-axiom.0xc1.space`, group `public`, conditions `[STATUS] == any(200, 302, 401, 403)`, `[CERTIFICATE_EXPIRATION] > 336h`, `[RESPONSE_TIME] < 3000`.
- Optional fourth endpoint if validation shows public reachability is safe: `opencode-charlie` with the same auth-aware status condition.

The auth-aware condition allows Cloudflare Access or app auth to return 401/403 while still proving the public route, TLS, and edge path are alive. Do not include private database/Redis/message queue hostnames in the public status page for this first version.

### Prometheus Integration

Extend `modules/services/prometheus.nix` minimally so it can accept scrape configs or a Gatus scrape toggle without forcing a full monitoring topology.

Preferred minimal shape:

- Add `modules.services.prometheus.scrapeConfigs` as a list of attrsets, default `[]`.
- Pass it into `services.prometheus.scrapeConfigs` when Prometheus is enabled.
- Let `modules.services.gatus.prometheusScrape.enable` append one `job_name = "gatus"` scrape config when both modules are enabled.

This keeps Prometheus optional for hosts that only want a status page. `acorn` should explicitly enable Prometheus in this task so the first deployment has a real in-repo scrape job. The runbook should also show the equivalent standalone scrape YAML for external Prometheus deployments.

### Runbook

Add `docs/gatus-status.md` or `hosts/acorn/modules/status.md` with:

- How to add an endpoint: name, group, URL, interval, conditions, `extra-labels`.
- Local validation: `nix flake check`, targeted `nix build .#nixosConfigurations.acorn.config.system.build.toplevel`, and option eval checks.
- Status page access: `https://status.0xc1.space` after DNS/ACME is configured.
- Prometheus queries: `gatus_results_endpoint_success`, `gatus_results_duration_seconds`, `gatus_results_total`, plus certificate metric if available.
- Troubleshooting: Gatus service logs, sqlite path, nginx vhost, ACME/DNS, Prometheus scrape target.

## Scope

In scope:

- Add `modules/services/gatus.nix`.
- Update `modules/services/prometheus.nix` only as needed for scrape config support.
- Add `hosts/acorn/modules/status.nix` and import it from `hosts/acorn/default.nix`.
- Add Gatus runbook documentation.
- Maintain Legion task evidence.

Out of scope:

- Secrets, alert channels, incident workflows, production deploy commands, DNS changes outside the repo, Cloudflare Access policy changes.

## Verification

Automated verification should include:

- `nix flake check` if feasible in the environment.
- Targeted acorn build: `nix build .#nixosConfigurations.acorn.config.system.build.toplevel`.
- Targeted eval of `services.gatus.enable`, Gatus settings, nginx vhost domain, and Prometheus scrape config shape.
- Static review that no endpoint URL includes private credentials, tokens, or internal-only hostnames beyond loopback self-check.

Manual/post-deploy verification should include:

- Confirm DNS for `status.0xc1.space` points to `acorn`.
- Confirm ACME certificate issuance succeeds.
- Confirm `https://status.0xc1.space` loads.
- Confirm Prometheus can scrape `/metrics` and queries return Gatus metrics.

## Rollback

Rollback is configuration-only:

- Disable `modules.services.gatus.enable` or remove `hosts/acorn/modules/status.nix` from imports.
- Remove the nginx vhost by clearing `modules.services.gatus.domain` or disabling the module.
- Remove the appended Prometheus scrape job by disabling `modules.services.gatus.prometheusScrape.enable` or disabling Prometheus on the host.
- Rebuild `acorn` to return to the previous generation.

Persistent sqlite data at `/var/lib/gatus/gatus.db` can remain unused after rollback or be manually deleted if the deployment is abandoned. No schema/data migration is required.

## Open Questions

- Is `status.0xc1.space` already provisioned in DNS, or should deployment docs mark it as a required manual step? This does not block repo configuration.
- Should `opencode-*` endpoints be visible on a public status page if they are protected by Cloudflare Access? First version treats them as route/TLS checks only and allows auth responses.

## Implementation Notes

- Keep the wrapper minimal; do not mirror the entire upstream Gatus config surface.
- Prefer `extraSettings` for uncommon upstream options instead of adding many first-class wrapper options.
- Do not open the Gatus port in the firewall.
- Keep endpoint labels consistent: `service`, `environment`, `owner`.

## References

- Plan: `.legion/tasks/gatus-status-page-blackbox-monitoring/plan.md`
- Linear: `0XC-7`
- Existing files: `modules/services/prometheus.nix`, `modules/services/nginx.nix`, `hosts/acorn/default.nix`, `hosts/acorn/modules/vaultwarden.nix`
- Gatus docs: conditions, metrics, storage, endpoint labels
