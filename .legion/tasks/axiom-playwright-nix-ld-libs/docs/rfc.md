# Design-lite: Playwright nix-ld runtime libraries

## Context

Axiom is a NixOS host with `modules.dev.playwright.enable = true`. The Nix-packaged `playwright` command already wraps Playwright with `PLAYWRIGHT_BROWSERS_PATH` pointing at Nix store browser builds, and that path can launch Chromium successfully.

The failing path is `npx` or project-local npm Playwright. On unsupported Linux distributions, Playwright downloads an Ubuntu fallback browser into the user browser cache. That browser is not patched by nixpkgs and resolves shared libraries through `nix-ld`; the current global `programs.nix-ld.libraries` list does not include `libglib-2.0.so.0` or several related Chromium runtime libraries.

## Options

1. Only use the Nix-packaged `playwright` wrapper.
   - Pros: already works; no extra dynamic libraries.
   - Cons: does not help npm/npx Playwright or project-local Playwright installs.

2. Pin or wrap npm/npx Playwright globally.
   - Pros: could force all callers through one controlled browser path.
   - Cons: larger policy change, likely brittle across project-local versions, and out of scope for this runtime failure.

3. Add the Chromium runtime libraries to `programs.nix-ld.libraries` when the Playwright dev module is enabled.
   - Pros: minimal host-level fix for downloaded browser binaries; preserves the existing Nix wrapper; reversible.
   - Cons: future Playwright browser versions may require additional libraries.

## Decision

Use option 3.

`modules/dev/playwright.nix` should keep installing `pkgs.playwright-test`, then add the Chromium runtime library set to `programs.nix-ld.libraries` on Linux only. The list is based on the Chromium and Chromium headless-shell dependencies used by nixpkgs' Playwright browser derivations and verified against the current failing `npx playwright@1.61.0` Chromium launch path.

## Scope

- Change `modules/dev/playwright.nix` only for runtime behavior.
- Add Legion task evidence under `.legion/tasks/axiom-playwright-nix-ld-libs/**`.
- Do not change host-specific Axiom enablement.
- Do not commit downloaded Playwright browsers or screenshots.

## Rollback

Revert the `modules/dev/playwright.nix` hunk that adds `programs.nix-ld.libraries`. The Nix-packaged `playwright` wrapper remains available because it already uses Nix store browsers.

## Verification

- `playwright screenshot --browser=chromium https://example.com <artifact>`
- npm/project-local Playwright Chromium launch with the configured nix-ld library set
- `nix eval --raw .#nixosConfigurations.axiom.config.system.build.toplevel.drvPath`
- `nix build .#nixosConfigurations.axiom.config.system.build.toplevel --dry-run`
