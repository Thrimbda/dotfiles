# Report Walkthrough

Mode: implementation

## Summary

- Added an axiom-specific user oneshot that recreates/prefers the NVIDIA DP/HDMI sink during graphical session startup.
- Ordered EasyEffects after that readiness step so Zen/Sidra streams do not get stranded on a virtual sink before HDMI exists.
- Verified the evaluated unit ordering, generated script, and full axiom NixOS toplevel build.

## Problem Evidence

- Direct ALSA playback to `hdmi:CARD=NVidia,DEV=0` produced sound through the DELL U2720QM headphone output.
- GUI applications were connected through PipeWire/Pulse to `Easy Effects Sink` while the real `alsa_output.pci-0000_01_00.1.hdmi-stereo` sink was initially missing.
- Reselecting the NVIDIA HDMI card profile recreated the sink and restored Zen/Sidra audio, making startup ordering and sink creation the target failure mode.

## Changed Files

- `hosts/axiom/default.nix`
  - Adds `axiomHdmiAudioCard` and `axiomHdmiAudioSink` constants.
  - Adds `axiom-ensure-hdmi-audio` script to wait for the NVIDIA card, reselect `output:hdmi-stereo`, and set the HDMI sink as default.
  - Adds `axiom-hdmi-audio.service` as a user-level oneshot after PipeWire/WirePlumber and before EasyEffects.
  - Adds EasyEffects `After`/`Wants` ordering on `axiom-hdmi-audio.service`.

## Verification Evidence

- `git diff --check`: PASS.
- Targeted `nix eval` checks: PASS for HDMI unit ordering, EasyEffects ordering, service type, and ExecStart path.
- Generated script inspection: PASS; the Nix store script contains fixed-string card matching, HDMI profile reselect, and default sink selection.
- `nix build --impure --no-link .#nixosConfigurations.axiom.config.system.build.toplevel`: PASS.

See `docs/test-report.md` for command-level details.

## Review Evidence

- `docs/review-change.md`: PASS with no blocking findings.
- Security lens: no trigger applies.
- Residual risk: final end-to-end proof requires deploying the generation and starting a fresh axiom graphical session.

## Rollout Notes

- Deploy the new axiom generation normally.
- On next graphical session start, `axiom-hdmi-audio.service` should run before EasyEffects.
- If audio still fails after deployment, inspect `systemctl --user status axiom-hdmi-audio.service easyeffects.service` and `wpctl status` first.
