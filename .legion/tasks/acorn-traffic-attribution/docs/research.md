# Research: Acorn Traffic Attribution

## Observed Problem

Billing Management attributes the excess cost entirely to Acorn ECS outbound traffic at 0.8 CNY/GB. The host's `vnstat` data confirms paired inbound/outbound spikes. Live systemd cgroup counters identify `sshd` as the dominant carrier: 298.83 GB ingress and 294.38 GB egress, compared with 5.56/5.36 GB for `frps`, 91/94 MB for `nginx`, and 671/669 MB for `rustdesk-relay`.

## Current Evidence

- The 2026-08-23 00:00-05:50 spike coincided with 2,383 FRP user connections, nearly all named `axiom-opencode-http`; the graph fell to zero when the FRP client disconnected. This is a correlation only: FRP's cgroup byte total is much smaller than SSH's.
- The 2026-08-24 16:00-18:59 spike coincided with 2,139 more `axiom-opencode-http` connections and no RustDesk relay session.
- FRP connection count is not byte accounting. One OpenCode browser health poll generated a new proxy connection about every ten seconds, while the large transfer may be an upgraded or long-lived stream.
- Existing Nginx access-log body counters do not account reliably for data transferred after HTTP protocol upgrade.

## Available Local Counters

- NixOS can enable IP accounting per systemd service cgroup, providing ingress and egress totals for candidate daemons.
- The deployed FRP 0.66 dashboard binds to `127.0.0.1:7500`. `/api/proxy/tcp` exposes each proxy's name, status, current connections, `todayTrafficIn`, and `todayTrafficOut`; `/api/traffic/<name>` also exists for a named proxy.
- `vnstat` remains the host-interface source of truth for aggregate traffic but cannot attribute the service path.
- Existing IP accounting is enabled for all four candidate services, but its current counters are volatile across service restart and not sampled into retained host state.

## Alternatives

1. Local FRP plus systemd counter samples: recommended. It is bounded, persistent, service/proxy-specific, and adds no public exposure.
2. Netdata or eBPF agent: can provide richer process/network correlation but adds a larger runtime, data retention policy, and monitoring surface.
3. Nginx access logs or FRP connection logs: insufficient because they undercount upgraded traffic and describe counts rather than bytes.
4. Packet capture: exposes content and identities, incurs high storage cost, and is disproportionate to the requirement.
