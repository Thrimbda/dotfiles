# RFC: Acorn Traffic Attribution

> **Profile:** High-risk infrastructure change
> **Status:** Approved for implementation
> **Owner:** OpenCode
> **Created:** 2026-08-24

## Executive Summary

- **Problem:** Live cgroup counters identify `sshd` as the primary traffic carrier, but the host cannot retain that evidence across restarts or compare it over time with FRP proxy counters.
- **Decision:** Sample FRP per-proxy counters and systemd service IP counters locally every five minutes.
- **Impact:** Operators can distinguish FRP proxy traffic from Nginx, RustDesk relay, and SSH service totals without capturing request content.
- **Risk:** Counters reset on daemon restart and local forwarding can be visible in more than one cgroup.
- **Rollout:** Build on Axiom, switch Acorn remotely, then verify the initial sample and local report.
- **Rollback:** Revert the host module import and switch Acorn to the preceding NixOS generation; retained local aggregate samples may be deleted manually if no longer needed.

## Goals

- Preserve enough local counter history to investigate future public-egress spikes.
- Attribute FRP traffic by named proxy and candidate host traffic by service cgroup.
- Keep all collection local, bounded, and inaccessible from the network.

## Non-Goals

- Packet capture, request logging, client identity tracking, or retroactive attribution.
- Changing proxy routing, public service availability, or cloud billing configuration.

## Proposed Design

Add `hosts/acorn/modules/traffic-accounting.nix` and import it from the Acorn host. The module will:

1. Explicitly preserve systemd IP accounting for `frps`, `nginx`, `rustdesk-relay`, and `sshd`.
2. Create a root-owned state directory with a 30-day retention policy.
3. Run a root-owned five-minute oneshot timer. The sampler reads the existing loopback FRP dashboard, extracts only TCP proxy names and traffic totals, reads systemd ingress/egress counter properties, and appends one compact JSON sample.
4. Install a local report command that compares the two newest samples, shows per-service and per-proxy deltas, and marks counter resets instead of emitting negative traffic.

The sampler does not read HTTP access logs or capture connections. If FRP is unavailable, it records `null` for the FRP section and still stores the systemd counter sample. It attributes SSH bytes to `sshd` only; remote-peer attribution is intentionally out of scope.

## Alternatives

### Netdata Or eBPF Monitoring

Richer process and socket views are possible, but they require a broader daemon, data lifecycle, and security design. They are deferred until aggregate service/proxy attribution is insufficient.

### Port Counters And Access Logs

Port counters cannot consistently assign reply traffic to a listener after connection tracking/NAT, and Nginx body counters omit upgraded streams. They are not sufficient as the primary attribution source.

## Security And Privacy

- The FRP dashboard remains bound to loopback; no listener or firewall rule changes.
- Samples contain timestamps, service names, proxy names, statuses, connection counts, and byte counters only.
- Sample files are root-owned and expire after 30 days.
- No request URL, query string, user agent, client IP, SSH command, payload, or credential is collected.

## Rollout And Rollback

1. Evaluate the Acorn configuration and inspect the generated units on Axiom.
2. Deploy using the mandated Axiom-to-Acorn `nixos-rebuild switch` command.
3. Confirm the sampler timer runs, a root-owned sample exists, and the report identifies current zero/small deltas without errors.

Rollback by reverting the module import and switching to the preceding NixOS generation from Axiom. This removes the timer and command but does not alter forwarding services. Delete `/var/lib/acorn-traffic-accounting` only if the operator explicitly wants to remove historical aggregate counters.

## Verification

- Nix evaluation proves every targeted service has IP accounting enabled and the timer is installed.
- Remote activation is built on Axiom.
- On Acorn, verify service/timer status, state-directory permissions, sample JSON shape, and report output.
- Confirm FRP, Nginx, RustDesk, and SSH remain active after activation.
