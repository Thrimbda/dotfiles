# Axiom Feishu Launcher ID Fix

## Goal

Make Feishu appear in the Axiom Caelestia launcher favourites by using the launcher id Quickshell actually assigns to the desktop entry.

## Problem

Live diagnosis showed Feishu is installed, `XDG_DATA_DIRS` includes the Feishu package `share` path, and `~/.config/caelestia/shell.json` contains the previous favourite value `bytedance-feishu.desktop`. Quickshell derives desktop-entry ids from `QFileInfo(fileName).completeBaseName()`, so `bytedance-feishu.desktop` is indexed as `bytedance-feishu`. The favourite entry therefore does not match the discovered app id.

## Acceptance

- Axiom Caelestia launcher favourites use `bytedance-feishu`.
- Existing mutable configs that contain `bytedance-feishu.desktop` are migrated to `bytedance-feishu` without removing unrelated favourites.
- Feishu remains installed and its upstream desktop file remains the discovery source.
- No Feishu account, cache, proxy, autostart, credential, organization policy, or non-Axiom host behavior changes.

## Scope

- `hosts/axiom/default.nix` Feishu launcher id and mutable-config migration.
- Task evidence under `.legion/tasks/axiom-feishu-launcher-id-fix/**`.
- Wiki updates correcting the Caelestia launcher id convention.

## Non-Goals

- Do not create a duplicate desktop entry.
- Do not replace Caelestia launcher or change the Feishu package.
- Do not manage Feishu runtime state.

## Design Summary

- Use `bytedance-feishu`, the Quickshell desktop-entry id derived from `bytedance-feishu.desktop`.
- Update the existing pre-start migration to remove the legacy incorrect favourite and append the correct id if missing.
- Validate the evaluated favourite id, migration script behavior, desktop-entry availability, and Axiom toplevel.

## Phases

1. Implement the id and migration correction.
2. Verify focused Nix and script behavior.
3. Review, walkthrough, wiki writeback, PR lifecycle, cleanup.
