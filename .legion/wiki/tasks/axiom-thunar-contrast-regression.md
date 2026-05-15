# Axiom Thunar Contrast Regression

## Metadata

- `task-id`: `axiom-thunar-contrast-regression`
- `status`: `active`
- `risk`: `low-medium`
- `schema-version`: `current`
- `historical`: `false`
- `supersedes`: `axiom-thunar-caelestia-theme-contrast` conclusion that package-level `Breeze-Dark` alone was sufficient for live Thunar contrast
- `superseded-by`: `(none)`

## Outcome Summary

This task fixes the follow-up Thunar contrast regression after `Breeze-Dark` was already selected. The live Axiom GTK settings reported `gtk-theme-name=Breeze-Dark`, but unmanaged GTK3 CSS in `~/.config/gtk-3.0/gtk.css` imported `thunar.css` and hard-coded pale Thunar surfaces such as `#f6faf9` and `#eef5f3`, leaving the Breeze-Dark foreground text nearly unreadable.

The implementation keeps the Breeze-Dark/FluentDark theme direction and adds repository-owned GTK3 CSS in `modules/desktop/apps/thunar.nix`. When Thunar is enabled, Home Manager now forces `.config/gtk-3.0/gtk.css` to a minimal `@import "thunar.css";` entry and forces `.config/gtk-3.0/thunar.css` to Thunar-scoped rules that use GTK theme color variables for main view, sidebar, path bar, status bar, selected items, and rubberband selection.

Verification passed at the final Home Manager layer for generated GTK3 CSS text and `force = true`, preserved `Breeze-Dark`, `git diff --check`, and the Axiom toplevel dry-run. No live switch was run; perceived contrast still needs a post-deploy Thunar smoke.

## Reusable Decisions

- For Axiom Thunar contrast, GTK theme selection is not enough evidence if `~/.config/gtk-3.0/gtk.css` or imported Thunar CSS exists outside repository ownership.
- Keep Thunar CSS rules scoped to `.thunar` selectors and use GTK theme variables rather than host-specific hard-coded palette values.
- If replacing stale live GTK CSS declaratively, force only the specific GTK3 CSS files needed for the bug and keep global `gtk.css` minimal.

## Related Raw Sources

- `plan`: `.legion/tasks/axiom-thunar-contrast-regression/plan.md`
- `log`: `.legion/tasks/axiom-thunar-contrast-regression/log.md`
- `tasks`: `.legion/tasks/axiom-thunar-contrast-regression/tasks.md`
- `test-report`: `.legion/tasks/axiom-thunar-contrast-regression/docs/test-report.md`
- `review`: `.legion/tasks/axiom-thunar-contrast-regression/docs/review-change.md`
- `walkthrough`: `.legion/tasks/axiom-thunar-contrast-regression/docs/report-walkthrough.md`
- `pr-body`: `.legion/tasks/axiom-thunar-contrast-regression/docs/pr-body.md`

## Notes

- After deployment, reopen Thunar and confirm file labels, sidebar labels, path buttons, and status bar text are readable.
- If Caelestia or another live process attempts to regenerate GTK3 CSS, keep repository ownership as the active source of truth for Thunar contrast unless a future task deliberately reopens mutable GTK CSS generation.
