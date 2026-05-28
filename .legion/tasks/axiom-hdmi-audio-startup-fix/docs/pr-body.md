## Summary

- Add an axiom-specific user oneshot to recreate/prefer the NVIDIA DP/HDMI sink at graphical session startup.
- Order EasyEffects after that readiness unit so browser audio streams do not get stranded before the real HDMI sink exists.
- Record Legion verification and review evidence for the repeated Zen/Sidra no-audio issue.

## Verification

- `git diff --check`
- `nix eval --impure .#nixosConfigurations.axiom.config.systemd.user.services.axiom-hdmi-audio.unitConfig.After`
- `nix eval --impure .#nixosConfigurations.axiom.config.systemd.user.services.easyeffects.unitConfig.After`
- `nix build --impure --no-link .#nixosConfigurations.axiom.config.system.build.toplevel`

## Notes

- Runtime recurrence prevention still needs deployment and a fresh graphical session on axiom.
