# Implementation Plan

## Step 1: Inventory Options

- Extend `modules.desktop.hyprland.monitors` with dynamic policy and optional Caelestia fields while keeping existing defaults static.
- Add Axiom monitor identity and policy fields in `hosts/axiom/default.nix`.

## Step 2: Runtime Reconcile Helper

- Generate a helper from the monitor inventory.
- Implement native-resolution/highest-refresh selection from `hyprctl monitors all -j`.
- Wire the helper into startup and reload.
- Add a Hyprland-session-scoped event watcher that debounces monitor events and invokes the helper.

## Step 3: Caelestia Per-Monitor Seeding

- Generate per-monitor JSON seed data from monitor entries with `caelestia.settings`.
- Seed mutable files under `~/.config/caelestia/monitors/<output>/shell.json` from the Caelestia pre-start path.

## Step 4: Verification

- Run targeted Nix evals for Hyprland and Caelestia generated files.
- Run syntax/static checks on generated shell scripts.
- Record live smoke commands for post-deploy validation.
