# Tasks

## Brainstorm

- [x] Confirm mode policy: native/highest-resolution first, then highest refresh at that resolution.
- [x] Capture Caelestia per-monitor config constraint from upstream docs.
- [x] Materialize task contract.

## Design

- [x] Write RFC for monitor inventory shape, runtime reconciliation, and Caelestia per-monitor ownership.
- [x] Review RFC and resolve design risks before implementation.

## Implementation

- [x] Open isolated worktree/PR envelope.
- [x] Implement cohesive monitor inventory and generated Hyprland runtime helper.
- [x] Add Caelestia per-monitor seed support from the same monitor inventory.
- [x] Update Axiom host config to use the new shape.

## Verification

- [x] Evaluate generated Axiom `hypr/monitors.conf`.
- [x] Evaluate Caelestia monitor config support and current pre-start integration.
- [x] Run static checks for generated scripts and Nix formatting/whitespace.
- [ ] Record live smoke commands for post-deploy validation.

## Delivery

- [x] Run implementation review.
- [x] Produce walkthrough/report evidence.
- [x] Write reusable monitor policy decisions/patterns to Legion wiki.
