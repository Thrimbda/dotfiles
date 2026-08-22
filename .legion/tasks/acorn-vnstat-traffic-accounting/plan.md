# Acorn vnStat Traffic Accounting

## Contract

- **Task ID:** `acorn-vnstat-traffic-accounting`
- **Risk:** high
- **Approval:** deferred to the implementation PR
- **Goal:** Declaratively enable persistent daily and monthly network accounting on Acorn.

## Problem

Alibaba Cloud bills Acorn public egress by usage. August usage reached 186.27701 GB and 149.02 CNY before month end, while the host had no local historical traffic counter. This prevents timely detection of a renewed egress spike.

## Acceptance

- Acorn's NixOS configuration enables the `vnstat` daemon and its persistent database.
- The `acorn` configuration evaluates successfully.
- Activation is built on Axiom and switched remotely, never built on Acorn.
- After activation, `vnstat` can read the primary network interface and `vnstat.service` is active.
- No new listening ports, public endpoints, firewall rules, or application services are introduced.

## Scope

- Declare the built-in NixOS `vnstat` service in Acorn's existing platform module.
- Validate and activate the configuration using the approved Axiom-to-Acorn deployment path.
- Record operator commands for reading aggregate daily and monthly traffic.

## Non-Goals

- Recovering historic per-service or per-process traffic usage.
- Changing Aliyun billing mode, bandwidth, public exposure, or any running public service.
- Sending traffic telemetry to an external service or creating alerts.

## Assumptions And Constraints

- `vnstat` interface-level counters are sufficient to detect future billing spikes.
- Existing Acorn traffic should remain uninterrupted during activation.
- Deployment must run from Axiom with the mandated remote rebuild command and interactive sudo password prompt.
- Existing untracked credential files in the primary checkout are out of scope and must not be read or committed.

## Risks

- Counters begin only after activation and cannot explain the current billing period retroactively.
- Interface-level totals do not identify the responsible service; RustDesk, FRP, Nginx, and other services remain aggregated.
- Remote activation can fail or change the host generation; the configuration change is limited and rollback is a Git revert followed by the same remote switch command.

## Design Summary

Enable the native NixOS `services.vnstat` daemon in `hosts/acorn/modules/platform.nix`. The daemon stores kernel-interface counter snapshots locally, requires no inbound port, and exposes local CLI reports. Formal detail and rollback are in `docs/rfc.md`.

## Phases

1. Record evidence and review the proposed service configuration.
2. Enable the service and validate the Acorn configuration.
3. Build on Axiom, remotely activate Acorn, and verify service and counter availability.
4. Complete review, delivery evidence, wiki writeback, and PR lifecycle.
