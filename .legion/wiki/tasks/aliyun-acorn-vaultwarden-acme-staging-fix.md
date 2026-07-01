# Aliyun Acorn Vaultwarden ACME Staging Fix

Status: ready for PR

## Summary

Fixes the post-PR #111 `aliyun-acorn` rebuild hang risk by treating the host as a low-resource server rather than a development machine. The change removes development, desktop/media, Docker, host `nix-ld`, and documentation closure weight; limits Nix concurrency; and makes SSH daemon-backed instead of socket-activated. The original local-only staging shape was superseded by `aliyun-acorn-https-firewall-ports`, which restores public HTTPS-only staging.

## Current Shape

- `aliyun-acorn` keeps SSH, fail2ban, frps, nginx, and staged Vaultwarden.
- `aliyun-acorn` no longer enables Node, Deno, Rust, Python, adl/media tooling, direnv, GnuPG pinentry stack, Docker, host `nix-ld`, or local documentation outputs.
- Docker service enablement and server-profile boot enablement are both forced off for `aliyun-acorn`.
- Nix on `aliyun-acorn` is limited to `max-jobs = 1`, `cores = 1`, and `http-connections = 4`.
- OpenSSH uses normal `sshd.service` daemon mode, not socket activation, and the inherited unsupported `GSSAPIAuthentication no` extra config is cleared for this host.
- `status-axiom.0xc1.wang` and `vault.0xc1.space` nginx vhosts were initially staged as local-only routes, but this was superseded by public HTTPS-only staging in `aliyun-acorn-https-firewall-ports`.
- Public firewall port `80` stays closed; public `443` is required for the staged vhosts.

## Reusable Decisions

- Low-resource public server hosts should not inherit development/desktop/media compatibility packages by default; keep only explicit service role dependencies.
- When ACME is disabled for an auth-bearing staged vhost, do not expose it over public HTTP. Use HTTPS-only staging with a temporary on-host certificate, or keep it loopback-only if public TLS is not required.
- For public low-resource SSH hosts under scan/load, persistent `sshd.service` can be preferable to socket-activated per-connection `sshd` because banner handling should not depend on systemd spawning a new daemon for each connection.

## Verification

- `nix build --impure --no-link .#nixosConfigurations.aliyun-acorn.config.system.build.toplevel` passed.
- Eval confirmed Vaultwarden remains enabled.
- Eval confirmed no generated ACME or Docker units.
- Eval confirmed firewall ports are `[22,2222,2225,7000,34197]`.
- Generated nginx config inspection originally confirmed loopback-only HTTP; this was superseded by follow-up HTTPS-only staging.
- Closure size dropped from about `5.5 GiB` to `3.2 GiB`.
- `review-change` passed with security lens applied.

## Operational Follow-up

- Remote `nixos-rebuild switch` is still not proven because `aliyun-acorn` timed out during SSH banner exchange during this task.
- ACME/real certificates for `vault.0xc1.space` and `status-axiom.0xc1.wang` must be restored in a DNS/TLS cutover task. Public `443` was restored earlier by `aliyun-acorn-https-firewall-ports`.
- If Docker is required for an untracked manual workload, create an explicit service decision before deploying that workload on `aliyun-acorn`.

## Source Evidence

- Raw task: `.legion/tasks/aliyun-acorn-vaultwarden-acme-staging-fix/`
- Test report: `.legion/tasks/aliyun-acorn-vaultwarden-acme-staging-fix/docs/test-report.md`
- Change review: `.legion/tasks/aliyun-acorn-vaultwarden-acme-staging-fix/docs/review-change.md`
- Walkthrough: `.legion/tasks/aliyun-acorn-vaultwarden-acme-staging-fix/docs/report-walkthrough.md`
