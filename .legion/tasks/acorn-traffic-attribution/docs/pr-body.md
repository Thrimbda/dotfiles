## Summary

Adds Acorn-local traffic attribution for future egress investigations.

- Sample systemd cgroup ingress/egress for FRPS, Nginx, RustDesk relay, and SSHD every five minutes.
- Sample named FRP TCP proxy traffic from the existing loopback dashboard API.
- Retain root-owned aggregate samples for 30 days and provide `sudo acorn-traffic-report` for interval deltas.

## Risk And Privacy

High-risk production-host change, deployed from Axiom only. It adds no listener, firewall rule, external telemetry, credential, client identity, request content, or payload capture. Stored state contains only timestamps, service/proxy names, status, connection counts, and byte totals.

## Validation

- Acorn Nix configuration evaluation passed.
- Required Axiom-to-Acorn build and switch passed.
- Timer, samples, report command, and the existing public-service baseline were verified on Acorn.

## Rollback

Revert the host module import and apply the preceding Acorn NixOS generation from Axiom. The collector is removed without altering forwarding services; local aggregate samples may be deleted manually if desired.

This PR body is review input and does not prove PR checks, review, merge, cleanup, or main-worktree refresh.
