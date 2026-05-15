# Report Walkthrough: Gatus Status Page Blackbox Monitoring

> **Mode**: implementation  
> **Date**: 2026-05-15  
> **Task**: `gatus-status-page-blackbox-monitoring` / Linear `0XC-7`

## What Changed

- Added `modules.services.gatus`, a minimal NixOS wrapper around upstream `services.gatus`.
- Enabled the first Gatus deployment on `acorn` through `hosts/acorn/modules/status.nix`.
- Added `status.0xc1.space` nginx reverse proxy with ACME/forceSSL and loopback Gatus binding.
- Added three initial endpoints: `vaultwarden-web`, `status-page`, and `opencode-axiom`.
- Extended `modules.services.prometheus` with mergeable `scrapeConfigs` and wired a Gatus `/metrics` scrape job.
- Added `docs/gatus-status.md` runbook for endpoint additions, validation, PromQL entrypoints, and troubleshooting.

## Design Alignment

The implementation follows the approved RFC:

- NixOS/acorn was chosen over Docker Compose/Kubernetes to match the repo architecture.
- Gatus remains black-box/status-page focused; Prometheus remains the white-box metrics system.
- Gatus binds to `127.0.0.1:8080`; public access goes through nginx only.
- The first endpoint inventory avoids private database/Redis/message queue targets.

Evidence: `docs/rfc.md`, `docs/review-rfc.md`.

## Verification

Accepted verification from `docs/test-report.md`:

- `nix build .#nixosConfigurations.acorn.config.system.build.toplevel --no-link` passed.
- Targeted eval confirmed nginx forceSSL/ACME for `status.0xc1.space`, Gatus loopback web binding, endpoint inventory, and Prometheus scrape config.
- Static scan found no token/password/secret or credential URL patterns in the new endpoint config/runbook.
- `nix flake check --no-build` failed on unchanged `apps.install = mkApp ./install.zsh` / `lib/nixos.nix`; this is recorded as an unrelated baseline blocker.

## Review Result

`docs/review-change.md` concluded PASS.

Security lens was applied because this adds a public status page and monitoring exposure boundary. No blocking security findings remain.

## Manual Follow-up

- Confirm DNS for `status.0xc1.space` points to `acorn`.
- Confirm ACME issuance after deployment.
- Confirm `https://status.0xc1.space` loads.
- Confirm deployed Prometheus scrapes Gatus `/metrics`.

## Reviewer Notes

- The Gatus wrapper intentionally keeps a small option surface and exposes `extraSettings` for uncommon upstream settings.
- Upstream `services.gatus` uses `DynamicUser=true` and `StateDirectory=gatus`; this change relies on that instead of adding custom tmpfiles ownership.
- Full flake check currently has an unrelated app schema issue outside this task's diff.
