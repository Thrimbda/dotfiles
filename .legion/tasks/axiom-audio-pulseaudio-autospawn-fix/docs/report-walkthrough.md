# Report Walkthrough

Mode: implementation

## What Changed

- Hardened `hosts/axiom/default.nix` so the Axiom HDMI readiness script clears any stray real `pulseaudio` daemon before forcing the NVIDIA HDMI profile/default sink.
- Added declarative user PulseAudio client config via `home.configFile."pulse/client.conf"` with `autospawn = no` and `force = true`.

## Why

The live no-audio incident was not just an EasyEffects routing problem. PipeWire logs showed `hdmi:0` was busy, and `pgrep -a pulseaudio` found a real `pulseaudio --start` process running alongside PipeWire. That process prevented PipeWire from creating the real HDMI sink, leaving only the EasyEffects virtual sink. After killing real PulseAudio and restarting WirePlumber, the NVIDIA HDMI sink returned and the Cyberpunk 2077 stream routed to `MPG272UX OLED`.

## Evidence

- `docs/test-report.md`: Nix eval confirms generated `.config/pulse/client.conf` text is `autospawn = no` and `force = true`.
- `docs/test-report.md`: Axiom toplevel derivation evaluates and `nix build --impure --dry-run .#nixosConfigurations.axiom.config.system.build.toplevel` succeeds.
- `docs/test-report.md`: plain `pactl info` without desktop runtime returns connection refused and does not autospawn real PulseAudio.
- `docs/test-report.md`: desktop `pactl info` reports `PulseAudio (on PipeWire 1.4.9)` with default sink `alsa_output.pci-0000_01_00.1.hdmi-stereo`.
- `docs/test-report.md`: `wpctl status` shows default sink `HDA NVidia 数字立体声 (HDMI)` and the active game stream outputs to `MPG272UX OLED`.
- `docs/review-change.md`: readiness review passed with no blocking findings.

## Reviewer Notes

- This is intentionally host-specific to Axiom because it depends on the host's chosen PipeWire stack and NVIDIA HDMI sink path.
- The `pkill -x pulseaudio` behavior is scoped to the user-session readiness script and is safe under the current Axiom assumption that real PulseAudio should not run.
- A reboot/session restart was not performed during the active desktop/game session; next natural login should be observed, but generated unit/file configuration is validated by Nix evaluation.
