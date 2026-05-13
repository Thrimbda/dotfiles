# Test Report

## Scope

Validate that Axiom declaratively enables the existing Playwright development module, that the evaluated user package closure contains the Playwright CLI package, and that the package-provided wrapper has the Nix browser path integration needed for Playwright runtime use.

## Commands

1. `nix eval --option eval-cache false --json .#nixosConfigurations.axiom.config.modules.dev.playwright.enable`
   - Result: PASS, output `true`.
   - Reason: directly verifies the host option introduced by this change is enabled.

2. `nix eval --option eval-cache false --json .#nixosConfigurations.axiom.config.users.users.c1.packages --apply 'packages: builtins.any (pkg: builtins.match "playwright-test-.*" (pkg.name or "") != null) packages'`
   - Result: PASS, output `true`.
   - Reason: verifies the evaluated Axiom user package set includes the Playwright package after module merging.

3. `nix eval --option eval-cache false --json .#nixosConfigurations.axiom.config.environment.shellAliases.pw`
   - Result: PASS, output `"playwright"`.
   - Reason: verifies the existing module also exposes the repository-standard short alias.

4. `nix build --option eval-cache false --print-out-paths --no-link .#nixosConfigurations.axiom.pkgs.playwright-test`
   - Result: PASS, output `/nix/store/x75n5dfy4gkfiqr6zh2skdl5qdq5cr0i-playwright-test-1.56.1`.
   - Reason: realizes the exact package used by the module without creating a repo-local result link.

5. `nix shell --option eval-cache false .#nixosConfigurations.axiom.pkgs.playwright-test -c playwright --version`
   - Result: PASS, output `Version 1.56.1`.
   - Reason: proves the CLI entrypoint can execute from the pinned package.

6. Read `/nix/store/x75n5dfy4gkfiqr6zh2skdl5qdq5cr0i-playwright-test-1.56.1/bin/playwright`.
   - Result: PASS, line 8 exports `PLAYWRIGHT_BROWSERS_PATH` to `/nix/store/6xfxz9kf3n0p28mpf3pyclvysgr7s5bs-playwright-browsers` by default.
   - Reason: proves the package wrapper supplies the browser dependency path under Nix instead of relying on mutable browser downloads.

7. `nix build --option eval-cache false .#nixosConfigurations.axiom.config.system.build.toplevel --dry-run`
   - Result: PASS.
   - Reason: verifies the Axiom NixOS toplevel remains evaluable/buildable with this host option enabled.

## Warnings

- The Nix commands emitted an existing warning about `specialArgs.pkgs` causing `nixpkgs.config` and overlay options to be ignored.
- The toplevel dry-run emitted existing deprecation or rename warnings for `mesa.drivers`, `hardware.pulseaudio`, and `system`.
- These warnings are not introduced by this task and did not block evaluation.

## Skipped

- No live `nixos-rebuild switch` was run, per contract.
- No browser launch smoke test was run in an Axiom graphical session. Runtime browser automation should be smoke-tested after deployment.
