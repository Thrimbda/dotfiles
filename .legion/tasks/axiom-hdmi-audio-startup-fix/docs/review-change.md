# Review Change

## Result

PASS

## Findings

No blocking findings.

## Scope Check

- The implementation is limited to `hosts/axiom/default.nix` plus task-local Legion evidence.
- It keeps PipeWire, WirePlumber, pipewire-pulse, EasyEffects, Zen, and Sidra in place.
- It does not change non-axiom hosts or redesign the generic audio module.

## Correctness Review

- `axiom-hdmi-audio.service` is a user-level oneshot ordered after `pipewire.service`, `pipewire-pulse.service`, and `wireplumber.service`, which targets the startup race observed in the live session.
- The generated script waits briefly for `alsa_card.pci-0000_01_00.1`, reselects `output:hdmi-stereo`, and sets `alsa_output.pci-0000_01_00.1.hdmi-stereo` as the default sink.
- `easyeffects.service` is ordered after and wants `axiom-hdmi-audio.service`, so the EasyEffects virtual sink should no longer become the only available output before the real HDMI sink is created.
- The card and sink identifiers match existing axiom-specific WirePlumber priority rules, keeping the host-specific assumption explicit.

## Verification Review

- Targeted `nix eval` checks confirm the intended systemd user unit ordering and service type.
- The generated script was inspected from the Nix store after build and contains the expected `pactl` commands with fixed-string card matching.
- `nix build --impure --no-link .#nixosConfigurations.axiom.config.system.build.toplevel` passed.

## Security Lens

No security trigger applies. The change does not modify auth, permissions, secrets, token handling, network exposure, or trust boundaries.

## Residual Risk

- End-to-end recurrence prevention still requires deploying the new generation and starting a fresh graphical session on axiom.
- Manually restarting `axiom-hdmi-audio.service` during active playback would briefly toggle the HDMI profile; normal startup use runs it before app playback begins.
