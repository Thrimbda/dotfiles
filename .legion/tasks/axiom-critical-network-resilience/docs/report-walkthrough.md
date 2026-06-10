# Report Walkthrough: Axiom Critical Network Resilience

Mode: implementation

## What Changed
- Added host-local OOM/resource protection for the critical network path on `axiom`: `sshd`, `autossh-reverse-ssh`, `cloudflared`, and `clash-verge` service-mode/core.
- Added a user-manager drop-in and Clash Verge GUI autostart drop-in so the GUI is no longer unnecessarily penalized with a positive OOM score.
- Added non-destructive healthcheck timers for cloudflared readiness, autossh reverse endpoint identity, and Clash service/core health.
- Added declarative global SSH known-host pinning for `8.159.128.125`; this does not write to `/home/c1/.ssh/known_hosts`.
- Added an explicit cloudflared metrics endpoint at `127.0.0.1:20241` and capped zram swap as a memory-pressure buffer.

## Why
The incident showed that `active` systemd state is not enough for these access paths. `cloudflared` can be active while `/ready` is unhealthy, and `autossh` can be active while remote forwarding is not usable. The change protects the core services from OOM selection and adds targeted health checks for the active-but-broken modes already observed.

## Safety Boundaries
- Autossh healthcheck compares the remote reverse endpoint host key against `axiom`'s local SSH host key. It does not accept a generic SSH banner as proof.
- Autossh healthcheck does not kill remote processes. If remote `127.0.0.1:2223` is held by a stale listener, it restarts local autossh and logs remote listener evidence for manual cleanup.
- Healthchecks are root systemd oneshots because they may restart system services; they keep counters under `/run/axiom-healthchecks`.
- No deployment command was run. `nixos-rebuild switch` remains an explicit post-review action.

## Verification
- Full `axiom` system build passed: `nix build --impure --no-link .#nixosConfigurations.axiom.config.system.build.toplevel`.
- Generated unit inspection confirmed expected OOM/resource settings and timers.
- `systemd-analyze verify` passed for generated healthcheck services/timers.
- `bash -n` passed for generated healthcheck scripts.
- Safe live checks passed for cloudflared `/ready`, autossh remote endpoint host-key identity, and Clash service/core predicates.

Evidence: `docs/test-report.md`.

## Review
`review-change` passed with security lens applied. No blocking findings were found.

Evidence: `docs/review-change.md`.

## Residual Risks
- A stale remote listener on `127.0.0.1:2223` may still require manual remote cleanup because automatic remote killing is intentionally excluded.
- Healthcheck timers can restart critical services after repeated transient failures.
- Live failure-threshold restart behavior was not forced before deployment to avoid intentional service disruption.

## Deployment Notes
After merge and explicit deployment approval, run the switch and inspect:
- `systemctl show autossh-reverse-ssh.service cloudflared.service clash-verge.service sshd.service -p OOMScoreAdjust -p MemoryMin -p MemoryLow -p OOMPolicy -p Restart -p RestartSec`
- `systemctl list-timers '*healthcheck*'`
- `curl --fail http://127.0.0.1:20241/ready`
- `systemctl --user show 'app-clash\x2dverge@autostart.service' -p OOMScoreAdjust -p MemoryLow -p Restart`
