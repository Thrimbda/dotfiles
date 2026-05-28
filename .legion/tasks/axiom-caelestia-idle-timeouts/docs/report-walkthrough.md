# Report Walkthrough - Axiom Caelestia Idle Timeouts

Mode: implementation.

## Summary

- Aligned Caelestia's own Axiom idle timers with Hypridle: 900 seconds to lock, 1800 seconds to DPMS off/on.
- Removed Caelestia's upstream 600 second `systemctl suspend-then-hibernate` idle action from Axiom-owned settings.
- Extended the existing Caelestia shell config migration so already-existing mutable `shell.json` files receive the same idle policy at session start.

## Why

Runtime investigation showed the active Hypridle service had the intended 900/1800 second listeners, but Caelestia shell also owns `IdleMonitors` through `GlobalConfig.general.idle.timeouts`. Without an Axiom override, Caelestia's upstream defaults can lock after 180 seconds, turn DPMS off after 300 seconds, and run sleep after 600 seconds. That made Caelestia win before Hypridle despite Hypridle being configured correctly.

## Implementation Walkthrough

`hosts/axiom/default.nix`

- Adds `caelestiaIdleSettings` with `lockBeforeSleep = true`, `inhibitWhenAudio = true`, and exactly two timeouts: `900 lock` and `1800 dpms off/on`.
- Applies that object to `modules.desktop.caelestia.settings.general.idle` so newly seeded Caelestia configs get the aligned policy.
- Renames the pre-start helper from a Feishu-only favorite migration to `axiom-ensure-caelestia-settings` and has it write `.general.idle = $idle` into existing mutable shell configs.
- Keeps the existing launcher favorite normalization for `bytedance-feishu` in the same helper.

`hosts/axiom/README.org`

- Documents that Hypridle remains the repository idle policy, while Caelestia's own shell idle monitors are intentionally aligned to the same 15 / 30 minute values.
- Documents that Axiom does not configure automatic idle sleep and that the pre-start migration only owns launcher favorites and `general.idle`.

`.legion/wiki/**`

- Updates current decisions, validation patterns, maintenance smoke checks, and task navigation for the aligned Caelestia/Hypridle policy.

## Verification Evidence

- `docs/test-report.md`: PASS.
- `git diff --check`: PASS.
- Targeted Nix assertions: PASS for Caelestia 900/1800 settings, exactly two timeouts, no sleep/hibernate/600 action, migration helper text, and Hypridle 900/1800/no-suspend values.
- Focused automatic sleep searches: PASS for active Axiom host and Hypridle config surfaces.
- jq migration filter syntax check: PASS.
- `nix build --no-link .#nixosConfigurations.axiom.config.system.build.toplevel`: PASS.

## Review Evidence

- `docs/review-change.md`: PASS with no blocking findings.
- Security lens was applied because the change touches session idle and power behavior; no blocker was found because the change removes an automatic sleep path and does not broaden permissions or add privileged boundaries.

## Post-Deploy Smoke

- Start a new Hyprland/Caelestia session.
- Confirm `~/.config/caelestia/shell.json` has `general.idle.timeouts` set to 900 second `lock` and 1800 second `dpms off` / `dpms on`, with no 600 second sleep action.
- Confirm active Hypridle logs still register 900 second lock and 1800 second DPMS listeners.
