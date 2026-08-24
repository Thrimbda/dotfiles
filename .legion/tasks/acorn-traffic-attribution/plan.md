# Acorn Traffic Attribution

## Contract

- **Task ID:** `acorn-traffic-attribution`
- **Risk:** high
- **Approval:** deferred to the implementation PR
- **Goal:** Persist local traffic counters that attribute Acorn egress to systemd services and FRP proxy names.

## Problem

Acorn has incurred repeated high public-egress charges. Current systemd counters identify `sshd` as the main carrier at roughly 299 GB ingress and 294 GB egress, close to the monthly billed volume; FRP, Nginx, and RustDesk counters are materially smaller. The host does not persist periodic counter snapshots, so a daemon restart or future spike would erase the evidence needed to repeat this attribution. Existing HTTP logs also undercount upgraded WebSocket/SSE traffic.

## Acceptance

- Every five minutes, Acorn saves root-owned local samples of FRP per-proxy traffic counters and systemd ingress/egress counters for `frps`, `nginx`, `rustdesk-relay`, and `sshd`.
- Samples retain no request paths, query strings, client IPs, tokens, packet payloads, or credentials, and expire after 30 days.
- A local report command compares the newest two samples and identifies byte deltas by service and FRP proxy name.
- The collector continues sampling when FRP is temporarily unavailable, explicitly recording that absence rather than reporting zero traffic.
- No listener, firewall rule, public endpoint, cloud resource, or external telemetry is added.
- Configuration evaluates on Axiom, is built on Axiom, and activates on Acorn through the mandated remote deployment command.

## Scope

- Add a host-local Acorn NixOS module for sampling, retention, and reporting.
- Explicitly preserve systemd IP accounting for the four candidate forwarding services.
- Use the existing loopback-only FRP dashboard API for proxy counters.

## Non-Goals

- Retroactively attributing the August traffic spike.
- Capturing packet payloads, HTTP paths, client identities, or SSH commands.
- Rotating shared SSH keys, remediating Nginx query-string logging, or disabling public services.
- Deploying Prometheus, Netdata, a database, or any externally reachable metrics endpoint.

## Assumptions And Constraints

- FRP 0.66's existing loopback dashboard exposes proxy traffic totals through its read-only API.
- systemd IP accounting exposes service cgroup counters on the deployed NixOS version.
- Counters can reset when their service restarts; samples must preserve the reset boundary and the report must not turn a reset into negative traffic.
- Axiom must build and activate; Acorn must never build its own closure.
- The password file in the dotfiles primary checkout may only be supplied to the remote sudo prompt and must not be read into output or committed.

## Risks

- Local forwarding can appear in more than one service cgroup; service counters must not be summed as if they were independent public egress.
- FRP or service restarts reset in-memory counters, so a sample interval may be incomplete.
- The sampler's persisted history is operational metadata; it is root-owned, contains only names and byte totals, and is retained for a bounded duration.
- SSH service counters attribute bytes to `sshd`, not an individual remote peer; peer-level accounting has a separate privacy and security boundary.

## Design Summary

The host-local module enables cgroup IP accounting for candidate services, samples those counters plus `frps` per-TCP-proxy totals every five minutes, and saves one JSON object per sample in a root-only state directory. A local `acorn-traffic-report` command compares the latest two samples. This uses existing loopback FRP data and kernel/systemd counters rather than opening a monitoring surface or exporting traffic elsewhere. Formal design and rollback are in `docs/rfc.md`.

## Phases

1. Record existing evidence, counter capabilities, and data boundaries.
2. Implement the sampler, report command, cgroup accounting, retention, and host import.
3. Validate configuration and deploy from Axiom to Acorn.
4. Verify persisted samples and attribution output, then complete review, wiki writeback, and PR lifecycle.
