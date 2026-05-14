# RFC: Axiom Thunar/Caelestia Theme Contrast

## Status

Proposed for implementation.

## Context

The reported Axiom Thunar screenshot shows a dark header bar with light content/sidebar surfaces and near-white labels. That produces unreadable file names and navigation entries. The repository currently selects Autumnal's GTK theme as `Graphite-pink-Dark`, while Caelestia's Qt integration is explicitly configured through `qtengine` with KDE's `BreezeDark.colors` and `style = "breeze"`.

Previous wiki guidance said current Axiom visual theming should avoid Catppuccin-specific visible assets in Thunar/file explorer and Fcitx. The new user direction supersedes that narrow assumption: the goal is to align GTK/Thunar and Fcitx with the active Caelestia theme direction, and Autumnal/Graphite can be replaced if it is the source of the contrast mismatch.

## Goals

- Restore readable Thunar text/background contrast under Axiom's Caelestia desktop session.
- Align GTK theming with the existing Caelestia/qtengine BreezeDark direction.
- Give Fcitx a declarative visible theme aligned with the same dark desktop direction.
- Update durable wiki truth so future work does not inherit the stale categorical anti-Catppuccin rule.

## Non-Goals

- No live edits to `~/.config/gtk-*`, Thunar, Fcitx, or Rime state.
- No live `nixos-rebuild switch` in this task.
- No redesign of Caelestia shell, qtengine, Hyprland, or Thunar behavior.
- No user-private dictionary, schema, bookmark, or file-manager state changes.

## Options

### Option A: Breeze-Dark GTK plus generic Fcitx theme support

Use `pkgs.kdePackages.breeze-gtk` with GTK theme name `Breeze-Dark`, matching the existing qtengine `BreezeDark.colors`/`style = "breeze"`. Extend the Fcitx module so `theme.package` and `theme.name` can select a non-Catppuccin theme, while retaining Catppuccin defaults for existing users. Set Axiom Fcitx to `pkgs.fcitx5-fluent` with theme `FluentDark` as a neutral dark input-method surface.

Pros:
- Directly aligns GTK with the current Qt/Caelestia BreezeDark integration.
- Avoids fragile Thunar-specific CSS overrides.
- Keeps Fcitx declarative and no longer hard-coded to Catppuccin.
- Preserves existing Fcitx Catppuccin behavior for other users unless they opt into a different package/name.

Cons:
- Fcitx does not have an exact Breeze packaged theme in current nixpkgs; `FluentDark` is a closest neutral dark packaged choice rather than a one-to-one Breeze port.
- Changing Autumnal's GTK theme may affect other Linux hosts using the Autumnal theme.

### Option B: Thunar-specific GTK CSS override

Keep `Graphite-pink-Dark` and add a targeted GTK CSS override for Thunar/icon/sidebar text and background colors.

Pros:
- Smallest visible blast radius if only Thunar is broken.
- Keeps existing Autumnal GTK package choice intact.

Cons:
- Treats the symptom rather than the theme mismatch.
- GTK CSS selectors for Thunar are brittle across GTK/Thunar versions.
- Does not align Fcitx with the current Caelestia direction.

### Option C: Return to Catppuccin across GTK and Fcitx

Select Catppuccin GTK and Fcitx variants to restore a single palette.

Pros:
- Strong palette consistency between GTK and Fcitx.
- Existing Fcitx module already supports Catppuccin naming.

Cons:
- Does not match the current qtengine BreezeDark configuration without further Qt/Caelestia changes.
- Reopens broader desktop theming choices beyond the reported Thunar contrast regression.

## Decision

Choose Option A.

The primary broken surface is GTK/Thunar, and the strongest current source of truth for Caelestia UI integration is `programs.qtengine` using BreezeDark. KDE's packaged `breeze-gtk` provides a maintained GTK3/GTK4 theme with coherent dark view/background/text colors, which directly addresses the screenshot's mixed dark-text-on-light or light-text-on-light symptom. Fcitx should become generically themeable instead of remaining Catppuccin-only; Axiom can then select `FluentDark` as a packaged neutral dark theme while leaving future Catppuccin choices possible.

## Implementation Plan

- Change Autumnal GTK theme from `Graphite-pink-Dark` to `Breeze-Dark` using `pkgs.kdePackages.breeze-gtk`.
- Extend `modules/desktop/input/fcitx5.nix` with generic `theme.package` and nullable `theme.name` options while preserving the current Catppuccin default name derived from `flavor` and `accent`.
- Set Axiom Fcitx theme declaratively to `enable = true`, `package = pkgs.fcitx5-fluent`, and `name = "FluentDark"`.
- Update wiki decisions/patterns/task summary to replace the stale categorical "avoid Catppuccin" conclusion with the current BreezeDark/FluentDark direction and allow future scoped Catppuccin work if deliberately chosen.

## Verification Plan

- Evaluate Axiom GTK theme metadata and assert `theme.name == "Breeze-Dark"`.
- Evaluate Axiom Fcitx theme settings and assert `Theme == "FluentDark"`.
- Evaluate Fcitx addons and assert `fcitx5-fluent` is present and `catppuccin-fcitx5` is not pulled solely by the theme path.
- Build or dry-run the Axiom NixOS toplevel.
- Run `git diff --check`.
- Record that final Thunar/Fcitx visual contrast requires post-switch live-session smoke.

## Rollback

- Restore Autumnal GTK `Graphite-pink-Dark` and remove the Axiom Fcitx `FluentDark` override.
- If only Fcitx regresses, keep Breeze-Dark GTK and revert Axiom Fcitx to `theme.enable = false` or the prior Catppuccin-derived module default.
- If Breeze-Dark introduces broader GTK regressions, split a follow-up with live screenshots and compare Breeze-Dark against a deliberate Catppuccin GTK/Qt/Fcitx direction.
