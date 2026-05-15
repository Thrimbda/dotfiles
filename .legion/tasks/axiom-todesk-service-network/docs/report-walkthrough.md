# Walkthrough: Enable ToDesk service networking on axiom

Mode: implementation

## Summary

- Added a host-local tmpfiles rule so `/var/lib/todesk` exists with `0700 c1 users` permissions.
- Added a host-local `systemd.services.todesk` unit that runs `${pkgs.todesk}/bin/todesk service` as `c1` after `network-online.target`.
- Kept the change scoped to `axiom`; no firewall rules, package versions, reusable modules, or live system switch are changed.

## Why

The ToDesk GUI was installed, but runtime diagnosis showed two missing pieces:

- The Nix package wrapper requires `/var/lib/todesk` to exist before launch.
- The GUI had no external sockets until `todesk service` was running; once running, `ToDesk_Service` owned the external HTTPS connection and the GUI connected over localhost.

## Review Notes

- Service runs as `c1`, not root.
- State directory is `0700` because ToDesk writes auth/private data under `/var/lib/todesk`.
- No inbound firewall ports are opened.

## Evidence

- Contract: `.legion/tasks/axiom-todesk-service-network/plan.md`
- Verification: `.legion/tasks/axiom-todesk-service-network/docs/test-report.md`
- Review: `.legion/tasks/axiom-todesk-service-network/docs/review-change.md`

## Verification Summary

- Nix evaluation confirmed the expected tmpfiles rule and systemd service fields.
- Live socket evidence confirmed `ToDesk_Service` owns the external HTTPS connection and the GUI talks to it over localhost.

## Not Done

- Did not run `nixos-rebuild switch`.
- Did not add firewall rules.
- Did not attempt to support unattended pre-login remote access.
