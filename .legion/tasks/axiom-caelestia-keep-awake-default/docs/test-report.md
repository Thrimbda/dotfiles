# Test Report: Axiom Caelestia Keep Awake Default

## Verdict

PASS

## Environment

- Worktree: `.worktrees/axiom-caelestia-keep-awake-default/`
- Branch: `legion/axiom-caelestia-keep-awake-default-reuse`
- Base: `origin/master` at `00c242d3`
- Date: 2026-05-14

## Commands

### Targeted Nix Assertions

Command:

```sh
nix eval --impure --json --expr 'let flake = builtins.getFlake (toString ./.); cfg = flake.nixosConfigurations.axiom.config; lib = flake.lib; names = builtins.attrNames cfg.systemd.user.services; service = cfg.systemd.user.services.axiom-caelestia-keep-awake; exec = service.serviceConfig.ExecStart; packageNames = map (p: p.name or "") cfg.users.users.c1.packages; hasReadme = builtins.pathExists ./hosts/axiom/README.org; readme = if hasReadme then builtins.readFile ./hosts/axiom/README.org else ""; in { hasKeepAwakeService = lib.elem "axiom-caelestia-keep-awake" names; serviceWantedByHyprland = lib.elem "hyprland-session.target" service.wantedBy; serviceWantsCaelestia = lib.elem "caelestia-shell.service" service.wants; serviceAfterCaelestia = lib.elem "caelestia-shell.service" service.after; execUsesKeepAwakeScript = lib.hasInfix "axiom-caelestia-keep-awake" exec; noAxiomSleepModeService = !(lib.elem "axiom-sleep-mode-apply" names) && !(lib.elem "axiom-no-sleep-inhibit" names); noAxiomSleepModePackage = !(lib.any (n: n == "axiom-sleep-mode") packageNames); noDirectHypridleOverride = !(cfg.home.configFile ? "hypr/hypridle.conf"); readmeDocumentsIdleInhibitor = lib.hasInfix "caelestia shell idleInhibitor enable" readme; readmeDocumentsSessionBoundary = lib.hasInfix "not a system-wide sleep policy" readme; }'
```

Result:

```json
{"execUsesKeepAwakeScript":true,"hasKeepAwakeService":true,"noAxiomSleepModePackage":true,"noAxiomSleepModeService":true,"noDirectHypridleOverride":true,"readmeDocumentsIdleInhibitor":true,"readmeDocumentsSessionBoundary":true,"serviceAfterCaelestia":true,"serviceWantedByHyprland":true,"serviceWantsCaelestia":true}
```

Why chosen: this proves the new Caelestia-backed service exists and is tied to the Hyprland/Caelestia session, while the old Axiom wrapper package/services/direct Hypridle override are absent.

### Host-Level Old Wrapper Search

Command:

```sh
grep equivalent for `axiom-sleep-mode|Power Mode|axiom-no-sleep-inhibit|axiom-sleep-mode-apply|maybe-suspend` under `hosts/axiom/*.{nix,org}`
```

Result: PASS, no matches.

Why chosen: catches stale user-facing docs or host declarations for the superseded custom wrapper.

### Diff Check

Command:

```sh
git diff --check
```

Result: PASS with no output.

### Axiom Toplevel Build

Command:

```sh
nix build --impure .#nixosConfigurations.axiom.config.system.build.toplevel --no-link
```

Result: PASS.

Relevant build evidence:

- Built `axiom-caelestia-keep-awake.drv`.
- Built `unit-axiom-caelestia-keep-awake.service.drv`.
- Built `nixos-system-axiom-25.11.20260203.e576e3c.drv`.

Warnings observed: existing nixpkgs/specialArgs and deprecated option/package warnings unrelated to this task remained present.

## Skipped Live Checks

No live suspend, hibernate, or long idle test was run from this tool session.

Post-deploy smoke on Axiom should verify:

- `caelestia shell idleInhibitor isEnabled` reports enabled after login.
- The Caelestia Keep Awake UI shows enabled by default.
- Toggling Keep Awake in Caelestia updates the same state.
- The behavior is understood as graphical-session scoped; it is not a headless/system-wide sleep policy.

## Post-Rebase Validation

After rebasing onto latest `origin/master`, conflicts were resolved in `hosts/axiom/default.nix`, `hosts/axiom/README.org`, and `.legion/wiki/log.md`. The resolution preserved upstream Axiom opencode PATH/service wiring, audio priority config, FluentDark Fcitx theme, and Cloudflare Access wiki updates while keeping this task's Caelestia Keep Awake replacement.

Commands rerun after conflict resolution:

```sh
nix eval --impure --json --expr '... opencodePathPreserved = true; fcitxThemeKept = true; ...'
git diff --check
nix build --impure .#nixosConfigurations.axiom.config.system.build.toplevel --no-link
```

Result: PASS. The targeted assertions included the original Keep Awake booleans plus `opencodePathPreserved=true` and `fcitxThemeKept=true`.
