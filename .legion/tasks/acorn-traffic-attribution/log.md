# Log

## 2026-08-24

- Billing evidence: Acorn public egress cost 111.02 CNY for 138.77 GB on 2026-08-22 and 61.13 CNY for 76.42 GB on 2026-08-23.
- `vnstat` recorded a further 20.55 GiB outbound on 2026-08-24, concentrated in a 16:00-18:59 window.
- FRP logs correlate the high-traffic windows with `axiom-opencode-http` connection activity but do not record bytes.
- The existing FRP dashboard is loopback-only on port 7500. Its `/api/serverinfo`, `/api/proxy/tcp`, and `/api/traffic/<name>` endpoints expose read-only traffic fields.
- Live systemd evidence identifies the current main carrier: `sshd` reports 298.83 GB ingress and 294.38 GB egress, while `frps` reports 5.56/5.36 GB, `nginx` 91/94 MB, and `rustdesk-relay` 671/669 MB.
- Chose local bounded samples from FRP counters plus systemd cgroup counters over request logging, external telemetry, or packet capture.
- Added a host-local five-minute sampler, 30-day root-owned retention, and root-only delta report command. The module explicitly keeps IP accounting enabled for the measured service cgroups.
- Deployed from Axiom with the mandated remote switch command. The timer is active, samples are `root:root` mode `0640`, and the report produced distinct service and proxy deltas.
- Implementation PR #204 merged. The implementation worktree was removed; this closeout change records the terminal task state.
