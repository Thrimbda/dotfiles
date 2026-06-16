# Test Report

## Summary

PASS. The declarative Axiom configuration evaluates, the dry-run system build reaches a valid derivation plan, PulseAudio autospawn is disabled for non-session `pactl` use, and the live graphical session remains routed to the real NVIDIA HDMI sink.

## Commands

1. `nix eval --impure --expr '(builtins.getFlake "git+file:///home/c1/dotfiles/.worktrees/axiom-audio-pulseaudio-autospawn-fix").nixosConfigurations.axiom.config.home-manager.users.c1.home.file.".config/pulse/client.conf".text'`

Result: PASS

Output: `"autospawn = no\n"`

2. `nix eval --impure --expr '(builtins.getFlake "git+file:///home/c1/dotfiles/.worktrees/axiom-audio-pulseaudio-autospawn-fix").nixosConfigurations.axiom.config.home-manager.users.c1.home.file.".config/pulse/client.conf".force'`

Result: PASS

Output: `true`

3. `nix eval --impure .#nixosConfigurations.axiom.config.system.build.toplevel.drvPath`

Result: PASS

Output: `/nix/store/mb7qxqqr899zwrxaqw8g4vp58d8s95vd-nixos-system-axiom-25.11.20260203.e576e3c.drv`

4. `nix build --impure --dry-run .#nixosConfigurations.axiom.config.system.build.toplevel`

Result: PASS

Output: dry-run planned 31 derivations, including `hm_.configpulseclient.conf.drv`, `axiom-ensure-hdmi-audio.drv`, and `unit-axiom-hdmi-audio.service.drv`.

5. `pgrep -a pulseaudio`

Result: PASS

Output: no running real PulseAudio process.

6. `pactl info` without `XDG_RUNTIME_DIR` / desktop DBus environment

Result: PASS

Output: `连接失败：拒绝连接`; follow-up `pgrep -a pulseaudio` still returned no process. This confirms the immediate `~/.config/pulse/client.conf` and declarative `home.configFile."pulse/client.conf"` behavior prevent libpulse from autospawning real PulseAudio in this shell context.

7. `XDG_RUNTIME_DIR=/run/user/1000 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus pactl info`

Result: PASS

Output: server name is `PulseAudio (on PipeWire 1.4.9)` and default sink is `alsa_output.pci-0000_01_00.1.hdmi-stereo`.

8. `XDG_RUNTIME_DIR=/run/user/1000 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus wpctl status`

Result: PASS

Output: default sink is `HDA NVidia 数字立体声 (HDMI)` at volume `0.80`; Cyberpunk 2077 stream outputs to `MPG272UX OLED:playback_FL/FR`.

## Why These Checks

- The Nix eval checks prove the persistent user PulseAudio client configuration is generated and can replace the manually-created runtime file on switch.
- The Axiom toplevel eval and dry-run prove the host configuration remains evaluable and includes the changed audio unit/file derivations.
- The live runtime checks prove the current incident is resolved and the observed root cause, real PulseAudio autospawn, is blocked in the same non-session shell context that reproduced it.

## Skipped

- Full `nix build` was not run because the dry-run was sufficient for this small host-specific configuration change and avoids building unrelated derivations locally.
- A reboot/session restart verification was not run in this turn to avoid disrupting the active desktop/game session; the readiness unit and generated Home Manager file are validated by evaluation.
