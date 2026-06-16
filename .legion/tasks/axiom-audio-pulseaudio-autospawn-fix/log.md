# Axiom Audio PulseAudio Autospawn Fix - Log

## 2026-06-16

- Runtime diagnosis found the shell without `XDG_RUNTIME_DIR` connected to a separate real PulseAudio server, while the graphical session used PipeWire's Pulse server.
- `wpctl status` in the graphical session initially exposed only `Easy Effects Sink`; `pactl list sinks` had no real HDMI hardware sink.
- PipeWire logs reported `spa.alsa: 'hdmi:0': playback open failed: Device or resource busy`.
- `pgrep -a pulseaudio` showed `pulseaudio --start`, which should not be running on this PipeWire host.
- Killing real PulseAudio and restarting WirePlumber recreated `alsa_output.pci-0000_01_00.1.hdmi-stereo`.
- Stopping EasyEffects moved the active Cyberpunk 2077 stream to `MPG272UX OLED` and restored sound.
- Implemented host-specific hardening in `hosts/axiom/default.nix`: disable PulseAudio autospawn via `home.configFile."pulse/client.conf"` and clear stray `pulseaudio` in `axiom-ensure-hdmi-audio`.
- For immediate runtime effect, `/home/c1/.config/pulse/client.conf` was also created with `autospawn = no`; the declarative config uses `force = true` so a later Home Manager switch can own it.
