# RFC: Acorn vnStat Traffic Accounting

> **Profile:** High-risk infrastructure change
> **Status:** Approved for implementation
> **Owner:** OpenCode
> **Created:** 2026-08-22

## Executive Summary

- **Problem:** Acorn's egress is billable, while the host retains no daily or monthly network history.
- **Decision:** Enable the native NixOS `vnstat` service in the Acorn platform module.
- **Impact:** A persistent local database will provide interface-level traffic reports after deployment.
- **Risk:** The service does not provide retroactive or per-process attribution.
- **Rollout:** Evaluate locally on Axiom, then use the prescribed remote rebuild command.
- **Rollback:** Revert the one-line service declaration and run the same remote rebuild command from Axiom.

## Goals

- Retain daily and monthly aggregate network usage for Acorn.
- Keep traffic accounting local and non-network-facing.
- Preserve the existing Acorn service and firewall topology.

## Non-Goals

- Historical billing attribution before installation.
- Per-service, per-user, or per-connection accounting.
- Automated billing alerts or cloud billing configuration changes.

## Constraints

- Acorn must not build its own closure.
- No public listener, firewall exception, secret, or cloud credential may be added.
- Configuration must be fully declarative and reversible by a NixOS generation rollback or Git revert.

## Proposed Design

Set `services.vnstat.enable = true` in `hosts/acorn/modules/platform.nix`. NixOS will provide and manage the daemon, which snapshots kernel interface counters into local state. Operators can use `vnstat` over the existing SSH path to read daily and monthly totals.

This changes only host-local observability. It does not intercept or alter packets, configure routing, or expose a new service.

## Alternatives

### Process-Level Accounting

Tools such as eBPF-based monitors could identify the responsible service. They require additional retention, privilege, and reporting design, so they are deferred until aggregate data demonstrates a continued issue.

### Cloud Flow Logs Or External Telemetry

These could provide central visibility but add cloud resource, cost, credential, and privacy scope. They are not justified for this immediate monitoring gap.

## Rollout And Rollback

1. Evaluate the `acorn` NixOS configuration on Axiom.
2. Build and switch remotely from Axiom with the mandated `nixos-rebuild` command.
3. Confirm `vnstat.service` is active and `vnstat` reports the primary interface.

Rollback conditions are failed activation, unexpected resource consumption, or degraded host service. Revert the configuration declaration or select the preceding NixOS generation from Axiom, then verify existing public services remain active. The traffic database may be retained because it contains local aggregate counters only; deleting it is not part of normal rollback.

## Observability And Security

- `systemctl status vnstat` confirms daemon health.
- `vnstat --days` and `vnstat --months` provide local aggregate reports.
- The service has no network listener and requires no firewall change.
- The database stores interface totals, not packet payloads, credentials, or application data.

## Verification

- Evaluate the Acorn configuration on Axiom.
- Complete the remote switch from Axiom.
- On Acorn, verify the service is active and the CLI reports its primary interface.
- Confirm current public services remain active after the switch.

## References

- Contract: `../plan.md`
- Research: `research.md`
- Target configuration: `hosts/acorn/modules/platform.nix`
