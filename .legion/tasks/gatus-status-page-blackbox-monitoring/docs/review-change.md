# Review Change: Gatus Status Page Blackbox Monitoring

> **Status**: PASS  
> **Reviewed**: 2026-05-15  
> **Scope**: `modules/services/gatus.nix`, `modules/services/prometheus.nix`, `hosts/acorn/**`, `docs/gatus-status.md`, Legion task evidence

## Blocking Findings

None.

## Security Lens

Applied, because the change adds a public status page and changes monitoring exposure boundaries.

Security assessment:

- Gatus binds to `127.0.0.1:8080`; public access is only through the nginx vhost for `status.0xc1.space`.
- The Gatus port is not opened in the firewall.
- Initial endpoints are public-safe: `vault.0xc1.space`, loopback Gatus self-check, and the already-public `opencode-axiom.0xc1.space` route/TLS check.
- Static scan found no token/password/secret patterns or credential-bearing URLs in the new endpoint config or runbook.
- No auth/session/token handling, secrets, or private dependency URLs were introduced.

## Correctness / Maintainability

- The implementation matches the approved RFC: NixOS/acorn deployment, sqlite storage, metrics enabled, nginx reverse proxy, Prometheus scrape job, and runbook.
- The upstream Gatus service already owns state via `DynamicUser=true` and `StateDirectory=gatus`; an extra tmpfiles rule was removed during review and revalidated.
- `modules.services.prometheus.scrapeConfigs` is a minimal extension and does not force Prometheus on hosts that do not enable it.
- `hosts/acorn/modules/status.nix` keeps endpoint inventory host-local and reviewable.

## Verification Review

Accepted evidence:

- `nix build .#nixosConfigurations.acorn.config.system.build.toplevel --no-link` passed before and after the review fix.
- Targeted eval confirmed nginx `forceSSL`/`enableACME`, Gatus loopback web binding, endpoint inventory, and Prometheus scrape config.
- Full `nix flake check --no-build` failed on unchanged `apps.install = mkApp ./install.zsh` / `lib/nixos.nix`; this is a documented baseline blocker and not attributable to the Gatus change.

## Non-blocking Notes

- Deployment still needs DNS/ACME/runtime confirmation for `status.0xc1.space` on `acorn`.
- If a future public status page should hide protected `opencode-*` route names, split public and private Gatus views in a separate task.

## Decision

PASS. The scoped change is ready for walkthrough, wiki writeback and PR delivery.
