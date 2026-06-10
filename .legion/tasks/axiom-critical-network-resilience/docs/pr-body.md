## Summary
- Harden `axiom` critical network services with OOM/resource priority for `sshd`, autossh, cloudflared, and Clash service-mode/core.
- Add non-destructive healthcheck timers for cloudflared readiness, autossh reverse endpoint identity, and Clash service/core health.
- Add declarative SSH known-host pinning, Clash GUI/user-manager drop-ins, explicit cloudflared metrics, and capped zram swap.

## Verification
- `nix build --impure --no-link .#nixosConfigurations.axiom.config.system.build.toplevel`
- Targeted `nix eval` checks for OOM/resource values, timers, known-host pinning, zram, and user drop-ins
- Generated unit/config inspection for systemd services, timers, `/etc/ssh/ssh_known_hosts`, cloudflared config, and zram config
- `systemd-analyze verify` for generated healthcheck services/timers
- `bash -n` for generated healthcheck scripts
- Safe live checks for cloudflared `/ready`, autossh remote endpoint host-key identity, and Clash service/core predicates

## Notes
- No `nixos-rebuild switch` was run.
- Autossh healthcheck does not kill remote processes; stale remote `2223` listeners are detected/logged for manual cleanup.
- Direct script execution as an unprivileged user fails as expected because the healthchecks are root systemd oneshots.
