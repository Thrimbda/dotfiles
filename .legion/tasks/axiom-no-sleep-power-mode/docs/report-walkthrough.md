# Walkthrough: Axiom No-Sleep Power Mode

Mode: implementation

## Summary

- Adds an Axiom-local no-sleep power mode that is the default when no user mode state exists.
- Keeps sleep available through an explicit desktop switch to allow-sleep mode.
- Avoids changing other hosts by overriding only Axiom's generated Hypridle config and leaving the global Hypridle source untouched.

## Problem Solved

Axiom inherited the repository Hypridle config that suspends the desktop after idle time. That is unsafe as the workstation default because it can interrupt remote access and long-running local tasks. The user wanted the default to be no-sleep while still keeping a desktop switch back to sleep-allowed behavior.

## Implementation

Production file changed: `hosts/axiom/default.nix`.

What changed:

- Adds `axiom-sleep-mode`, a fixed-verb script with `no-sleep`, `allow-sleep`, `toggle`, `apply`, `maybe-suspend`, and `status` verbs.
- Adds desktop launcher entries for `Power Mode: No Sleep`, `Power Mode: Allow Sleep`, and `Power Mode: Toggle Sleep`.
- Overrides Axiom's generated `hypr/hypridle.conf` so the suspend listener calls `axiom-sleep-mode maybe-suspend` instead of direct `systemctl suspend || loginctl suspend`.
- Adds `axiom-no-sleep-inhibit.service`, a user service that runs `systemd-inhibit --what=sleep --mode=block ... sleep infinity` while no-sleep mode is active.
- Adds `axiom-sleep-mode-apply.service`, wanted by `hyprland-session.target`, so the selected mode is applied when the desktop session starts.

## Design Evidence

- `docs/rfc.md` selected the Axiom-local script + Hypridle override + sleep inhibitor design.
- `docs/review-rfc.md` passed the design gate with no blocking findings.

## Verification Evidence

`docs/test-report.md` records PASS for:

- Targeted Nix assertions proving the generated Axiom Hypridle override, unchanged global Hypridle source, no-sleep inhibitor, apply service, script package, and launcher package presence.
- `git diff --check`.
- `nix build --impure .#nixosConfigurations.axiom.config.system.build.toplevel --no-link`.

The build produced the generated Hypridle file, `axiom-sleep-mode`, the new launcher derivations, both user services, and the Axiom system toplevel.

## Review Evidence

`docs/review-change.md` verdict is PASS.

Security lens was applied because the change affects power/session behavior. The review found no blocking issue because the change does not widen polkit permissions, does not grant `ignore-inhibit`, and keeps the new behavior as user-owned Axiom session tooling.

## Residual Work

Live checks remain post-deploy smoke because triggering suspend/hibernate or waiting through long idle windows is disruptive in this tool session:

- Confirm `axiom-sleep-mode status` on the live desktop.
- Confirm launcher entries switch modes.
- Confirm `systemd-inhibit --list` shows the Axiom inhibitor in no-sleep mode.
- Confirm lock and DPMS still work.
- Confirm no-sleep mode skips auto-suspend.
- Confirm allow-sleep mode permits the existing suspend behavior when deliberately selected.
