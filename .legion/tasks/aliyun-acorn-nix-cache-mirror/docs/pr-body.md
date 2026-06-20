## Summary

- Add a host-level TUNA Nix binary cache mirror for `aliyun-acorn`.
- Keep existing nix-community Cachix, Hyprland Cachix, and `cache.nixos.org` as fallback substituters.
- Document verification, review, and temporary one-off cache override usage in Legion evidence.

## Verification

- `nix eval '.#nixosConfigurations.aliyun-acorn.config.nix.settings.substituters' --json`
- `nix eval '.#nixosConfigurations.aliyun-acorn.config.system.build.toplevel.drvPath'`

## Legion Evidence

- Plan: `.legion/tasks/aliyun-acorn-nix-cache-mirror/plan.md`
- Design-lite: `.legion/tasks/aliyun-acorn-nix-cache-mirror/docs/rfc.md`
- Test report: `.legion/tasks/aliyun-acorn-nix-cache-mirror/docs/test-report.md`
- Review: `.legion/tasks/aliyun-acorn-nix-cache-mirror/docs/review-change.md`
- Walkthrough: `.legion/tasks/aliyun-acorn-nix-cache-mirror/docs/report-walkthrough.md`

## Notes

- This does not change `flake.nix` inputs or GitHub fetch behavior.
- This does not add new trusted public keys.
- PR lifecycle is not complete until checks/review and merge or blocker handling finish.
