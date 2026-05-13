## Summary

- Enable Axiom's existing `modules.dev.playwright` module so the host gets the Playwright CLI declaratively.
- Use the repository's current Playwright module rather than project-level npm dependencies or mutable browser downloads.
- Record verification, review, and handoff evidence under `.legion/tasks/axiom-playwright-cli-runtime/`.

## Verification

- `nix eval --option eval-cache false --json .#nixosConfigurations.axiom.config.modules.dev.playwright.enable`
- `nix eval --option eval-cache false --json .#nixosConfigurations.axiom.config.users.users.c1.packages --apply 'packages: builtins.any (pkg: builtins.match "playwright-test-.*" (pkg.name or "") != null) packages'`
- `nix eval --option eval-cache false --json .#nixosConfigurations.axiom.config.environment.shellAliases.pw`
- `nix build --option eval-cache false --print-out-paths --no-link .#nixosConfigurations.axiom.pkgs.playwright-test`
- `nix shell --option eval-cache false .#nixosConfigurations.axiom.pkgs.playwright-test -c playwright --version`
- `nix build --option eval-cache false .#nixosConfigurations.axiom.config.system.build.toplevel --dry-run`

## Notes

- No live `nixos-rebuild switch` was run.
- Runtime browser launch should be smoke-tested on Axiom after deployment.
