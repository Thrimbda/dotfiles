# Axiom Thunar Caelestia Theme Contrast

## Metadata

- `task-id`: `axiom-thunar-caelestia-theme-contrast`
- `status`: `active`
- `risk`: `medium`
- `schema-version`: `current`
- `historical`: `false`
- `supersedes`: `axiom-caelestia-permissions-theme-cleanup` visual-theme conclusion that categorically avoided Catppuccin visible assets
- `superseded-by`: `axiom-thunar-contrast-regression`

## Outcome Summary

This task fixes the reported Axiom Thunar contrast regression by moving GTK theming away from `Graphite-pink-Dark` and toward the active Caelestia/qtengine direction. Autumnal now selects KDE `Breeze-Dark` through `pkgs.kdePackages.breeze-gtk`, matching the existing qtengine `BreezeDark.colors` setup.

Fcitx visible theming is now declaratively themeable by package/name instead of being hard-coded to Catppuccin. Axiom selects `fcitx5-fluent` with `Theme=FluentDark`, while existing Catppuccin defaults remain available for other users or future scoped theme work.

The current effective conclusion is no longer “avoid Catppuccin assets categorically.” The current Axiom Caelestia visual direction is BreezeDark GTK/Qt alignment plus a neutral dark Fcitx theme; Catppuccin remains an allowed future direction only if a scoped task deliberately aligns GTK, Fcitx, and Qt/Caelestia together. This task's package-level GTK conclusion was later refined by `axiom-thunar-contrast-regression`, which found that live GTK3 Thunar CSS also needed repository ownership.

Static verification passed for generated GTK metadata, Home Manager GTK settings, qtengine color scheme, Fcitx settings/config/addons, `git diff --check`, and the Axiom toplevel dry-run. Final perceived contrast remains a post-switch live Thunar/Fcitx smoke check.

## Reusable Decisions

- For current Axiom Caelestia theming, align GTK with qtengine by using `Breeze-Dark`/`breeze-gtk` while qtengine uses `BreezeDark.colors`.
- Fcitx visible theme selection should support a generic theme package/name; keep Catppuccin as the default module behavior, but allow host-specific themes such as `fcitx5-fluent`/`FluentDark`.
- Do not patch Thunar-specific GTK CSS before proving a maintained package-level theme cannot solve the contrast issue.
- Headless validation can prove generated theme state, but real Thunar and Fcitx contrast still requires a live Axiom graphical-session smoke.

## Related Raw Sources

- `plan`: `.legion/tasks/axiom-thunar-caelestia-theme-contrast/plan.md`
- `log`: `.legion/tasks/axiom-thunar-caelestia-theme-contrast/log.md`
- `tasks`: `.legion/tasks/axiom-thunar-caelestia-theme-contrast/tasks.md`
- `rfc`: `.legion/tasks/axiom-thunar-caelestia-theme-contrast/docs/rfc.md`
- `rfc-review`: `.legion/tasks/axiom-thunar-caelestia-theme-contrast/docs/review-rfc.md`
- `test-report`: `.legion/tasks/axiom-thunar-caelestia-theme-contrast/docs/test-report.md`
- `review`: `.legion/tasks/axiom-thunar-caelestia-theme-contrast/docs/review-change.md`
- `walkthrough`: `.legion/tasks/axiom-thunar-caelestia-theme-contrast/docs/report-walkthrough.md`
- `pr-body`: `.legion/tasks/axiom-thunar-caelestia-theme-contrast/docs/pr-body.md`

## Notes

- After deployment, open Thunar and confirm file and sidebar labels are readable against their backgrounds.
- After deployment, trigger Fcitx in a text field and confirm the candidate UI uses `FluentDark` with readable contrast while Rime/Pinyin still work.
