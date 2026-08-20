# Report Walkthrough: Dotfiles Prune and Host Framework Extraction

## Mode

implementation

## Reviewer Summary

This change removes closed raw Legion evidence after preserving the wiki layer, deletes the stale root README, inventories one-off package modules, and finishes the Axiom/Acorn host-boundary cleanup without introducing a new framework.

- Raw task directories: 145 to 1.
- `hosts/axiom/default.nix`: 2174 to 179 lines.
- `hosts/acorn/default.nix`: 273 to 45 lines.

## What Changed

- Kept shared modules limited to Auth Mini process mechanics, Cloudflared tunnel naming, DNS-01 certificate expansion and reverse-SSH host-key mechanics.
- Moved concrete Axiom topology and policy into focused host-local modules for Acorn connectivity, autossh, Caelestia, Cloudflare, Qwen, RustDesk and workstation policy.
- Moved Acorn platform, ingress and RustDesk server composition into host-local modules while existing service-local modules retain their own proxy/TLS ownership.
- Preserved upstream Qwen runtime closure and warning-cleanup changes through repeated rebases.
- Recorded package-only modules as inline, unused-catalog or keep candidates without changing them.

## Behavior Preserved

- Public hostnames, IPs, ports, tunnel identifiers, firewall exposure, secret paths and service users are unchanged.
- Axiom reverse SSH, FRP, gateways, Cloudflared, Qwen, Caelestia, package order, RustDesk and workstation policy match normalized baseline snapshots.
- Acorn platform, gateways, all eight certificates/TLS attachments and RustDesk server policy match normalized baseline snapshots.
- Charlie's Cloudflared generated config and launchd service remain equivalent.

The only intentional delta disables Acorn's inert Hypridle default; neither baseline nor candidate creates a Hyprland or Hypridle unit.

## Verification

See `docs/test-report.md`.

Passed:

- one-task whitelist, 142-file baseline wiki retention, protected-file checks and `git diff --check`
- parsing of all 22 changed Nix files
- candidate Axiom, Acorn and Charlie derivation evaluation
- normalized baseline/candidate behavioral snapshots
- baseline and candidate Axiom 28-derivation dry-run plans

Candidate and baseline full flake checks retain the same existing `apps.install` schema failure.

## Review

See `docs/review-change.md`.

Decision: PASS. The security lens found no exposure, permission, secret-handling or privileged-command regression.

## Residual Risk

No live deployment occurred. Runtime reachability, service state and desktop behavior remain post-deploy smoke checks; Acorn was not built or activated.
