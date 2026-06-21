# Test Report

## Summary

Result: PASS

The change was verified against both Playwright invocation paths that matter for this task:

- The system `playwright` wrapper still launches Chromium through nixpkgs-managed browsers.
- A project-local npm Playwright install can launch its downloaded Ubuntu fallback Chromium when the same nix-ld library set configured by this change is provided.

The Axiom NixOS configuration also evaluates and plans a build successfully.

## Commands

### System Playwright wrapper

Command:

```bash
playwright screenshot --browser=chromium https://example.com .legion/tasks/axiom-playwright-nix-ld-libs/scratch/artifacts/system-playwright.png
```

Result: PASS

Evidence:

```text
Navigating to https://example.com
Capturing screenshot into .legion/tasks/axiom-playwright-nix-ld-libs/scratch/artifacts/system-playwright.png
```

### Axiom configuration evaluation

Command:

```bash
nix eval --raw .#nixosConfigurations.axiom.config.system.build.toplevel.drvPath
```

Result: PASS

Evidence:

```text
/nix/store/bjy9lc33z5pn6qb6j4j3iqvm66jp4pb2-nixos-system-axiom-25.11.20260203.e576e3c.drv
```

### Axiom dry-run build planning

Command:

```bash
nix build .#nixosConfigurations.axiom.config.system.build.toplevel --dry-run
```

Result: PASS

Evidence:

```text
these 30 derivations will be built:
  /nix/store/...-ld-library-path.drv
  /nix/store/...-nixos-system-axiom-25.11.20260203.e576e3c.drv
```

Nix also printed a transient eval-cache busy warning; the command still completed successfully and produced the dry-run build plan.

### npm Playwright downloaded browser

Command:

```bash
NPM_CONFIG_CACHE="$PWD/.legion/tasks/axiom-playwright-nix-ld-libs/scratch/npm-cache" \
  npm install --prefix ".legion/tasks/axiom-playwright-nix-ld-libs/scratch/pw-check" playwright@1.61.0 --no-save

PLAYWRIGHT_BROWSERS_PATH="$PWD/.legion/tasks/axiom-playwright-nix-ld-libs/scratch/pw-browsers" \
  ".legion/tasks/axiom-playwright-nix-ld-libs/scratch/pw-check/node_modules/.bin/playwright" install chromium

PW_LIBS=$(nix eval --raw --apply 'pkgs: pkgs.lib.makeLibraryPath (with pkgs; [ alsa-lib at-spi2-atk atk cairo cups dbus expat glib gobject-introspection libgbm libxkbcommon nspr nss pango stdenv.cc.cc.lib systemd xorg.libX11 xorg.libXcomposite xorg.libXdamage xorg.libXext xorg.libXfixes xorg.libXrandr xorg.libxcb libGL vulkan-loader pciutils ])' .#nixosConfigurations.axiom.pkgs)

NIX_LD_LIBRARY_PATH="$PW_LIBS:$NIX_LD_LIBRARY_PATH" \
PLAYWRIGHT_BROWSERS_PATH="$PWD/.legion/tasks/axiom-playwright-nix-ld-libs/scratch/pw-browsers" \
  node -e "(async()=>{const { chromium } = require('./.legion/tasks/axiom-playwright-nix-ld-libs/scratch/pw-check/node_modules/playwright'); const b = await chromium.launch({ headless: true }); console.log(await b.version()); await b.close();})().catch(e=>{console.error(e); process.exit(1);})"
```

Result: PASS

Evidence:

```text
BEWARE: your OS is not officially supported by Playwright; downloading fallback build for ubuntu24.04-x64.
Chrome for Testing 149.0.7827.55 (playwright chromium v1228) downloaded
FFmpeg download retried after a closed connection and a timeout, then succeeded from the third mirror.
Chrome Headless Shell 149.0.7827.55 (playwright chromium-headless-shell v1228) downloaded
149.0.7827.55
```

## Why These Commands

- The screenshot command proves the existing Nix-packaged `playwright` wrapper still works.
- The project-local npm Playwright command reproduces the path that failed with `libglib-2.0.so.0` and verifies the configured library set resolves it.
- `nix eval` verifies the modified Nix module remains evaluable.
- `nix build --dry-run` verifies the Axiom system closure can be planned without building or switching the host.

## Skipped

- `nixos-rebuild switch` was not run. The persistent fix will apply to the live host after the PR lands and Axiom is rebuilt/switched.
- Full system build was not run because dry-run build planning is sufficient for this small Nix module change and avoids unnecessary local build cost.
