# Enable ToDesk service networking on axiom

## Goal

Make ToDesk usable on the `axiom` NixOS host after declarative deployment by ensuring the runtime state directory exists and the ToDesk background service is managed by systemd.

## Problem

`pkgs.todesk` is installed on `axiom`, but the packaged launcher expects `/var/lib/todesk` to exist and the GUI depends on `ToDesk_Service` for network connectivity. Manual diagnosis showed the GUI process had no external sockets until `todesk service` was started, after which `ToDesk_Service` connected externally and the GUI connected to it over localhost.

## Acceptance

- `hosts/axiom/default.nix` declares a tmpfiles rule for `/var/lib/todesk` with ownership and permissions usable only by `c1`.
- `hosts/axiom/default.nix` declares a `systemd.services.todesk` unit that starts `todesk service` for `c1` after network-online.
- Nix evaluation confirms the axiom configuration contains the tmpfiles rule and service settings.
- Verification records the live diagnostic evidence that `todesk service` provides the network path.

## Scope

- `hosts/axiom/default.nix`
- `.legion/tasks/axiom-todesk-service-network`

## Non-Goals

- Do not change firewall rules or unrelated remote-access services.
- Do not introduce a reusable ToDesk module before there is another host consumer.
- Do not run `nixos-rebuild switch` in this task.
- Do not commit local secrets or unrelated untracked files such as `token.env`.

## Assumptions

- ToDesk state under `/var/lib/todesk` should be writable by `c1` because the Nix package binds it into both `/opt/todesk/config` and `/etc/todesk` for the GUI/service pair.
- Running the service as `c1` is sufficient for the current GUI connectivity problem and matches the successful manual diagnostic.
- `network-online.target` is an appropriate startup ordering point for a network-dependent remote desktop service.

## Constraints

- Keep the change host-local to `axiom`.
- Preserve the existing `pkgs.todesk` package source and version.
- Keep the implementation minimal and declarative.
- Use the `git-worktree-pr` lifecycle for delivery.

## Risks

- ToDesk is proprietary binary software; systemd-level validation cannot prove all runtime behaviors.
- Running the service as the desktop user may not support future unattended pre-login access; that is outside this task.
- Auto-starting a remote desktop service changes runtime exposure, so the task avoids broad firewall changes.

## Design Summary

- Add a tmpfiles rule to create `/var/lib/todesk` for `c1` and restrict directory traversal to the owning user.
- Add a host-local systemd service that runs `${pkgs.todesk}/bin/todesk service` as `c1` and restarts on failure.
- Validate through focused Nix evaluation and recorded live socket evidence rather than switching the live system.

## Phases

1. Contract: record the follow-up task because the previous install task explicitly excluded service enablement.
2. Implementation: add the tmpfiles rule and systemd service in `hosts/axiom/default.nix`.
3. Verification: evaluate the axiom configuration and record live diagnostic evidence.
4. Review: check scope, risks, and delivery readiness.
5. Delivery: produce walkthrough, PR body, wiki writeback, and PR lifecycle evidence.

---

Created: 2026-05-15
