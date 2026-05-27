## Summary

- Remove Axiom's obsolete `axiom-caelestia-never-sleep` script and user service.
- Preserve Caelestia Keep Awake startup enablement while making Hypridle the current idle lock/DPMS owner.
- Preserve the user's 15 minute lock and 30 minute DPMS timing, and update README/wiki current-truth guidance.

## Verification

- `! rg -n 'axiom-caelestia-never-sleep|caelestiaNeverSleep|Axiom Caelestia session defaults to never sleep' hosts/axiom config/hypr .legion/wiki/decisions.md .legion/wiki/patterns.md .legion/wiki/maintenance.md`
- `rg -n 'timeout = 900 # 15mins|timeout = 1800 # 30mins' config/hypr/hypridle.conf`
- `git diff --check`
- `nix eval --impure --json --expr 'let flake = builtins.getFlake (toString ./.); cfg = flake.nixosConfigurations.axiom.config; lib = flake.lib; hypridle = builtins.readFile ./config/hypr/hypridle.conf; startup = cfg.hey.hooks.startup; keepAwakeHook = startup."07-caelestia-keep-awake"; helperPath = builtins.elemAt (builtins.match ".*nohup ([^ ]+).*" keepAwakeHook) 0; helperText = builtins.readFile helperPath; in { noNeverSleepService = !(builtins.hasAttr "axiom-caelestia-never-sleep" cfg.systemd.user.services); hypridleLock900 = lib.hasInfix "timeout = 900 # 15mins" hypridle; hypridleDpms1800 = lib.hasInfix "timeout = 1800 # 30mins" hypridle; noSuspendCommand = !(lib.hasInfix "$suspend_cmd" hypridle || lib.hasInfix "systemctl suspend" hypridle || lib.hasInfix "loginctl suspend" hypridle); keepAwakePreserved = lib.hasInfix "idleInhibitor enable" helperText; }'`
- `nix build .#nixosConfigurations.axiom.config.system.build.toplevel --no-link`

## Legion Evidence

- Plan: `.legion/tasks/axiom-remove-never-sleep/plan.md`
- Test report: `.legion/tasks/axiom-remove-never-sleep/docs/test-report.md`
- Review: `.legion/tasks/axiom-remove-never-sleep/docs/review-change.md`
- Walkthrough: `.legion/tasks/axiom-remove-never-sleep/docs/report-walkthrough.md`
