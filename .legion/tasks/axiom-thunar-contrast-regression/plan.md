# Axiom Thunar Contrast Regression

## Goal

Restore readable Axiom Thunar text/background contrast after the previous Breeze-Dark theme alignment still left the live file manager with pale content surfaces and near-white labels.

## Problem

The prior task moved Autumnal GTK to `Breeze-Dark`, and the live GTK settings now report `gtk-theme-name=Breeze-Dark`. The new screenshot still shows Thunar with a dark header, light main/sidebar surfaces, and unreadable pale text. A read-only live check found unmanaged GTK3 CSS in `~/.config/gtk-3.0/gtk.css` importing `thunar.css`; that CSS defines light Thunar surfaces (`#f6faf9`, `#eef5f3`) while Breeze-Dark still supplies light foreground text. The issue is therefore a stale or external GTK3 CSS override, not just the selected GTK theme package.

## Acceptance

- [ ] Repository-owned declarative config replaces or overrides the stale GTK3 Thunar CSS path so Thunar main view, sidebar, path bar, and status bar use readable dark surfaces with readable text.
- [ ] The fix remains scoped to Thunar/GTK3 styling and does not hand-edit live `~/.config/gtk-*`, Thunar state, bookmarks, or file associations.
- [ ] Existing `Breeze-Dark` GTK and Axiom Fcitx theme decisions are preserved unless evidence proves they are the direct cause.
- [ ] Verification records Nix evaluation evidence for generated GTK files/settings and notes any post-switch live-session smoke that remains.

## Assumptions

- The screenshot is from Axiom after the previous Breeze-Dark change was deployed or partially deployed.
- Thunar is still GTK3, so `~/.config/gtk-3.0/gtk.css` and `thunar.css` are the effective override surface.
- The existing live `gtk.css`/`thunar.css` regular files are not currently repository-owned and can be superseded declaratively by Home Manager file ownership.

## Constraints

- Follow Legion workflow and use the git worktree PR envelope.
- Keep all repository changes inside the regression worktree.
- Do not run a live `nixos-rebuild switch` unless explicitly requested.
- Do not mutate user-private runtime files by hand; the fix must be declarative.

## Risks

- Forcing ownership of GTK3 `gtk.css` can replace external Caelestia-generated CSS; keep the file minimal and Thunar-specific to avoid broad GTK side effects.
- Home Manager activation may need to replace existing regular files; use declarative force only for the specific GTK3 CSS files needed for this bug.
- Headless validation can prove generated config, but perceived contrast still requires opening Thunar after deployment.

## Scope

- Add or adjust declarative ownership for GTK3 Thunar CSS.
- Preserve the previously merged Breeze-Dark GTK theme and Fcitx generic theme support.
- Update task evidence and wiki truth to mark the previous package-level theme switch as insufficient without owning stale GTK3 CSS.
- Run targeted Nix evaluations and repository diff checks.

## Non-Goals

- No redesign of Caelestia, qtengine, Hyprland, Fcitx, or global desktop theming.
- No manual deletion or editing of live `~/.config/gtk-3.0/gtk.css` or `thunar.css`.
- No changes to Thunar behavior, plugins, bookmarks, MIME handling, or file-manager state.
- No broad GTK4 CSS work unless evidence shows Thunar has moved to GTK4 in this environment.

## Design Summary

- Treat the regression as an unowned GTK3 CSS override that survived the Breeze-Dark theme switch.
- Prefer a small Thunar-scoped CSS override owned by the Thunar module over changing global theme selection again.
- Force ownership only for the GTK3 CSS files that currently carry the stale light Thunar styling, then keep the CSS aligned with theme colors where possible.

## Phases

1. Contract materialization for the regression follow-up.
2. Low-risk implementation of declarative Thunar GTK3 CSS ownership.
3. Verification via Nix evaluation/build checks and diff hygiene.
4. Review, walkthrough, PR handoff, and wiki writeback.

---

Created: 2026-05-15
