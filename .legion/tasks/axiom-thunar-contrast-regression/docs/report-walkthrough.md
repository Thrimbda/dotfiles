# Report Walkthrough

## Mode

Implementation.

## Summary

- Root cause shifted from the previous package-level theme choice to live GTK3 CSS ownership: Axiom already reports `Breeze-Dark`, but unmanaged `~/.config/gtk-3.0/gtk.css` imports a Thunar stylesheet that hard-codes light content surfaces.
- `modules/desktop/apps/thunar.nix` now owns `gtk-3.0/gtk.css` and `gtk-3.0/thunar.css` declaratively with `force = true`, replacing stale light CSS with Thunar-scoped rules based on GTK theme color variables.
- Verification passed at the final Home Manager layer and through Axiom toplevel dry-run; live visual confirmation remains a post-deploy smoke check.

## Files Changed

- `modules/desktop/apps/thunar.nix`: adds forced declarative GTK3 CSS ownership for Thunar and dark/readable Thunar selectors.
- `.legion/tasks/axiom-thunar-contrast-regression/plan.md`: captures the regression contract and root-cause evidence.
- `.legion/tasks/axiom-thunar-contrast-regression/docs/test-report.md`: records Nix eval, diff hygiene, and toplevel dry-run evidence.
- `.legion/tasks/axiom-thunar-contrast-regression/docs/review-change.md`: records readiness review PASS.

## Verification Evidence

- Final HM `gtk.css` text eval: PASS, output imports `thunar.css` only.
- Final HM `thunar.css` text eval: PASS, output uses theme variables for Thunar background/text/selection colors.
- Final HM `gtk.css.force` eval: PASS, output `true`.
- Final HM GTK theme eval: PASS, output `Breeze-Dark`.
- `git diff --check`: PASS.
- `nix build --option eval-cache false .#nixosConfigurations.axiom.config.system.build.toplevel --dry-run`: PASS.

## Review Result

- `docs/review-change.md`: PASS, no blocking findings.
- Security review: no security triggers present.

## Residual Risk

- The fix has not been live-switched in this task. After deployment, reopen Thunar and confirm the file grid, sidebar, path bar, and status bar all have readable contrast.
- The module applies to every host that enables Thunar. It uses GTK theme variables rather than hard-coded dark colors, so this is expected to remain readable for light or dark themes, but visual confirmation is still the only complete proof.
