## Summary

- Add a NixOS Gatus wrapper and enable the first `acorn` status page at `status.0xc1.space`.
- Configure initial black-box endpoints for Vaultwarden, the Gatus self-check, and the public opencode axiom route.
- Wire Gatus `/metrics` into Prometheus scrape config and document the runbook.

## Verification

- PASS: `nix build .#nixosConfigurations.acorn.config.system.build.toplevel --no-link`
- PASS: targeted eval for nginx `status.0xc1.space`, Gatus loopback web binding, endpoints, and Prometheus scrape config
- PASS: static scan for token/password/secret/credential URL patterns in new endpoint config and runbook
- Known unrelated blocker: `nix flake check --no-build` fails on unchanged `apps.install = mkApp ./install.zsh` / `lib/nixos.nix`

## Manual Follow-up

- Confirm DNS/ACME for `status.0xc1.space` during deployment.
- Confirm Prometheus scrapes `http://127.0.0.1:8080/metrics` after deploy.
