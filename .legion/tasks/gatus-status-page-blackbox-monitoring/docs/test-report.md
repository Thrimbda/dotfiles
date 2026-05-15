# Test Report: Gatus Status Page Blackbox Monitoring

> **Date**: 2026-05-15  
> **Result**: PASS for scoped Gatus/acorn changes, with one unrelated full-flake check blocker  
> **Worktree**: `.worktrees/gatus-status-page-blackbox-monitoring`

## Why These Checks

The change is NixOS configuration, not application runtime code. The strongest affordable validation is therefore:

- Build the affected host system closure for `acorn`.
- Evaluate the exact generated Gatus, nginx and Prometheus config shapes.
- Scan the new endpoint/runbook files for obvious secret-bearing strings.
- Attempt a broader flake check as a non-blocking regression signal.

## Commands

### 0. Review Fix Revalidation

During review, the extra tmpfiles rule for `/var/lib/gatus` was removed because upstream `services.gatus` already runs with `DynamicUser=true` and `StateDirectory=gatus`. The post-fix revalidation command was:

```sh
nix build .#nixosConfigurations.acorn.config.system.build.toplevel --no-link && \
nix eval .#nixosConfigurations.acorn.config.systemd.services.gatus.serviceConfig --json && \
nix eval .#nixosConfigurations.acorn.config.services.gatus.settings.web --json
```

Result: PASS.

Observed service config keeps upstream state handling:

```json
{"DynamicUser":true,"StateDirectory":"gatus","User":"gatus","Group":"gatus"}
```

### 1. Acorn System Build

```sh
nix build .#nixosConfigurations.acorn.config.system.build.toplevel --no-link
```

Result: PASS.

Evidence:

- Build completed successfully.
- The build generated `gatus.yaml`, `unit-gatus.service`, nginx config including `status.0xc1.space`, and Prometheus config/check artifacts.
- Nix emitted existing repository warnings about `specialArgs.pkgs` and renamed `system`, but no build failure.

### 2. Targeted Gatus/Prometheus/nginx Eval

```sh
nix eval .#nixosConfigurations.acorn.config.services.nginx.virtualHosts."status.0xc1.space".forceSSL
nix eval .#nixosConfigurations.acorn.config.services.nginx.virtualHosts."status.0xc1.space".enableACME
nix eval .#nixosConfigurations.acorn.config.services.gatus.settings.web --json
nix eval .#nixosConfigurations.acorn.config.services.prometheus.scrapeConfigs --json
```

Result: PASS.

Observed values:

```json
true
true
{"address":"127.0.0.1","port":8080}
[
  {
    "job_name": "gatus",
    "metrics_path": "/metrics",
    "scrape_interval": "30s",
    "static_configs": [
      {
        "labels": {
          "environment": "production",
          "service": "gatus"
        },
        "targets": ["127.0.0.1:8080"]
      }
    ]
  }
]
```

### 3. Endpoint Inventory Eval

```sh
nix eval .#nixosConfigurations.acorn.config.services.gatus.settings.endpoints --json
```

Result: PASS.

Observed endpoints:

- `vaultwarden-web` monitors `https://vault.0xc1.space` with HTTP 200, certificate expiry and response-time conditions.
- `status-page` monitors `http://127.0.0.1:8080` with HTTP 200 and response-time conditions.
- `opencode-axiom` monitors `https://opencode-axiom.0xc1.space` with auth-aware status, certificate expiry and response-time conditions.

### 4. Secret/String Static Scan

```sh
grep equivalent for: (token|password|secret|AKIA|cfut_|redis://|postgres://|mysql://)
targets:
  hosts/acorn/modules/status.nix
  docs/gatus-status.md
```

Result: PASS.

No matches were found in the new endpoint config or runbook.

### 5. Full Flake Check Smoke

```sh
nix flake check --no-build
```

Result: FAIL, unrelated to this change.

Failure:

```text
error: expected a string but found a path: /nix/store/...-source/install.zsh
at .../lib/nixos.nix:19:13: inherit program;
```

Assessment:

- `git diff --name-only -- flake.nix lib/nixos.nix` returned no files.
- The failure points at unchanged app output plumbing (`apps.install = mkApp ./install.zsh`).
- The targeted `acorn` build and targeted service evals passed, so this is treated as an existing full-flake check blocker rather than a Gatus implementation failure.

## Manual/Post-Deploy Checks

These require external state and were not executed here:

- Confirm DNS for `status.0xc1.space` points to `acorn`.
- Confirm ACME issuance for `status.0xc1.space` succeeds after deployment.
- Confirm `https://status.0xc1.space` loads.
- Confirm deployed Prometheus scrapes `http://127.0.0.1:8080/metrics` and PromQL returns Gatus metrics.

## Conclusion

Scoped verification passes. The implementation is ready for `review-change` with a documented unrelated `nix flake check --no-build` baseline blocker.
