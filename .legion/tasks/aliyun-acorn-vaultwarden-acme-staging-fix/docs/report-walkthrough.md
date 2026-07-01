# Walkthrough: Aliyun Acorn Low-Resource Rebuild Fix

## Mode

implementation

## Problem

After PR #111, `aliyun-acorn` repeatedly appeared to hang during `nixos-rebuild switch`. Live inspection showed the host had the PR #111 checkout but had not switched to a generation containing Vaultwarden. The active host also timed out during SSH banner exchange after a remote `nix build --dry-run`, pointing to low-resource Nix build/eval/download pressure rather than a confirmed Vaultwarden activation failure.

## What Changed

- Slimmed `aliyun-acorn` to a low-resource server profile by removing Node, Deno, Rust, Python, adl/media tooling, direnv, GnuPG pinentry stack, Docker, host `nix-ld`, and local documentation outputs.
- Added on-host Nix limits: `max-jobs = 1`, `cores = 1`, and `http-connections = 4`.
- Changed SSH from socket activation to normal daemon mode and removed the unsupported inherited `GSSAPIAuthentication no` extra config that was logging on each connection.
- Disabled staged ACME/forced SSL for `status-axiom.0xc1.wang` and `vault.0xc1.space` until DNS/TLS cutover is ready.
- Made both auth-bearing nginx vhosts local-only on `127.0.0.1:80` and forced the public firewall list to exclude `80/443`.

## Why This Shape

- The machine is explicitly not intended for development or desktop usage, so development runtimes and desktop/media compatibility packages are unnecessary cost.
- Socket-activated SSH was producing many per-connection daemon starts on a public host; normal daemon mode should be more resilient during load.
- Disabling ACME alone would have created public HTTP login surfaces. Local-only vhosts preserve staged testing through SSH tunneling without exposing Vaultwarden or BasicAuth over cleartext public HTTP.

## Verification

Evidence is recorded in `docs/test-report.md`.

- Vaultwarden remains enabled.
- Generated ACME units are empty.
- Generated Docker units are empty.
- OpenSSH is enabled with `startWhenNeeded = false` and empty `extraConfig`.
- Firewall ports are `[22,2222,2225,7000,34197]`.
- Generated nginx config has only `listen 127.0.0.1:80` for the staged vhosts.
- Full local build passed: `nix build --impure --no-link .#nixosConfigurations.aliyun-acorn.config.system.build.toplevel`.
- Closure dropped from about `5.5 GiB` to `3.2 GiB`.

## Review

Readiness review passed in `docs/review-change.md`. Security lens was applied because the change touches Vaultwarden/status HTTP exposure and SSH behavior.

## Residual Risks

- Remote `nixos-rebuild switch` is not proven because `aliyun-acorn` still times out during SSH banner exchange.
- Public HTTP/TLS for `status-axiom.0xc1.wang` and `vault.0xc1.space` must be re-enabled in a later DNS/TLS cutover task.
- If Docker is actually needed for an untracked manual workload, it needs an explicit service decision before deployment.
