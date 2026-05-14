## Summary

- Add an Axiom-local `axiom-sleep-mode` command and desktop launcher entries for no-sleep, allow-sleep, and toggle mode.
- Override only Axiom's generated Hypridle config so idle suspend routes through the mode command while lock/DPMS behavior remains intact.
- Add a user sleep-inhibitor service plus Hyprland-session apply service so no-sleep is the default and direct sleep requests are blocked while active.

## Validation

- `nix eval --impure --json --expr '...'` targeted assertions passed.
- `git diff --check` passed.
- `nix build --impure .#nixosConfigurations.axiom.config.system.build.toplevel --no-link` passed.

## Notes

- Live long-idle and suspend behavior was not triggered from this tool session because it is disruptive; post-deploy Axiom desktop smoke is documented in `docs/test-report.md`.
