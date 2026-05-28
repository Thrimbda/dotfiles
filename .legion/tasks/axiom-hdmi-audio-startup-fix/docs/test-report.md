# Test Report

## Summary

Status: PASS

The axiom configuration now evaluates a host-specific `axiom-hdmi-audio` user oneshot, orders it after PipeWire/WirePlumber, orders it before EasyEffects, and builds the axiom NixOS toplevel.

## Commands

1. `git diff --check`
   - Result: PASS
   - Purpose: catch whitespace issues in the Nix change before evaluation.

2. `nix eval --impure .#nixosConfigurations.axiom.config.systemd.user.services.axiom-hdmi-audio.unitConfig.After`
   - Result: PASS
   - Output: `[ "pipewire.service" "pipewire-pulse.service" "wireplumber.service" ]`

3. `nix eval --impure .#nixosConfigurations.axiom.config.systemd.user.services.axiom-hdmi-audio.unitConfig.Before`
   - Result: PASS
   - Output: `[ "easyeffects.service" ]`

4. `nix eval --impure .#nixosConfigurations.axiom.config.systemd.user.services.easyeffects.unitConfig.After`
   - Result: PASS
   - Output: `[ "graphical-session-pre.target" "axiom-hdmi-audio.service" ]`

5. `nix eval --impure .#nixosConfigurations.axiom.config.systemd.user.services.easyeffects.unitConfig.Wants`
   - Result: PASS
   - Output: `[ "axiom-hdmi-audio.service" ]`

6. `nix eval --impure --raw .#nixosConfigurations.axiom.config.systemd.user.services.axiom-hdmi-audio.serviceConfig.Type`
   - Result: PASS
   - Output: `oneshot`

7. `nix eval --impure --raw .#nixosConfigurations.axiom.config.systemd.user.services.axiom-hdmi-audio.serviceConfig.ExecStart`
   - Result: PASS
   - Output: `/nix/store/q8h7z2f26ankp9zkkaq7cxcp06p05c8a-axiom-ensure-hdmi-audio`

8. Read generated script `/nix/store/q8h7z2f26ankp9zkkaq7cxcp06p05c8a-axiom-ensure-hdmi-audio`
   - Result: PASS
   - Evidence: script waits for `alsa_card.pci-0000_01_00.1` with fixed-string matching, toggles that card to `output:hdmi-stereo`, then sets `alsa_output.pci-0000_01_00.1.hdmi-stereo` as the default sink.

9. `nix build --impure --no-link .#nixosConfigurations.axiom.config.system.build.toplevel`
   - Result: PASS
   - Evidence: built `nixos-system-axiom-25.11.20260203.e576e3c` after creating the new `axiom-ensure-hdmi-audio` and `unit-axiom-hdmi-audio.service` derivations; after the fixed-string grep correction the final toplevel derivation was `/nix/store/b7jjllc2k7wkkxbbsrc0z78sl0mp28d5-nixos-system-axiom-25.11.20260203.e576e3c`.

## Notes

- Nix evaluation emitted existing repository warnings about `specialArgs.pkgs`, deprecated `mesa.drivers`, renamed `system`, and renamed `hardware.pulseaudio`. These warnings are pre-existing and unrelated to this change.
- This validates declarative configuration and buildability. Full proof of startup behavior still requires deploying the new generation and starting a fresh graphical session on axiom.
