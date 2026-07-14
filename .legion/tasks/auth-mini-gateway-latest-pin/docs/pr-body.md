## Summary

- Pin auth-mini-gateway to upstream `3e4c273`.
- Refresh the source hash while retaining the unchanged Cargo dependency hash.
- Keep Acorn gateway policy and service configuration unchanged.

## Verification

- `git diff --check`
- `nix build --no-link --option substituters https://cache.nixos.org/ .#auth-mini-gateway`
- `nix build --no-link --option substituters https://cache.nixos.org/ .#nixosConfigurations.acorn.config.system.build.toplevel`
- All four evaluated gateway services reference the new package; review PASS.

## Evidence

- `.legion/tasks/auth-mini-gateway-latest-pin/docs/test-report.md`
- `.legion/tasks/auth-mini-gateway-latest-pin/docs/review-change.md`
- `.legion/tasks/auth-mini-gateway-latest-pin/docs/report-walkthrough.md`
