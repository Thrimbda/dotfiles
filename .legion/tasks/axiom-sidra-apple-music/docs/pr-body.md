## Summary

- Add Sidra as a pinned flake input for Apple Music desktop support.
- Add a small `modules.desktop.apps.sidra` module and enable it on `axiom`.
- Keep the change host-scoped and aligned with existing desktop app modules.

## Verification

- `nix eval .#nixosConfigurations.axiom.config.modules.desktop.apps.sidra.enable`
- `nix build --dry-run .#nixosConfigurations.axiom.config.system.build.toplevel`
- `nix build --no-link .#nixosConfigurations.axiom.config.system.build.toplevel`

## Legion Evidence

- Plan: `.legion/tasks/axiom-sidra-apple-music/plan.md`
- Test report: `.legion/tasks/axiom-sidra-apple-music/docs/test-report.md`
- Review: `.legion/tasks/axiom-sidra-apple-music/docs/review-change.md`
- Walkthrough: `.legion/tasks/axiom-sidra-apple-music/docs/report-walkthrough.md`
