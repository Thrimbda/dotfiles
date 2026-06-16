## Summary

- Disable PulseAudio client autospawn for Axiom via declarative `home.configFile."pulse/client.conf"`.
- Clear stray real `pulseaudio` before the existing Axiom HDMI readiness script forces the NVIDIA HDMI profile/default sink.
- Record Legion task evidence for diagnosis, verification, review, and walkthrough.

## Verification

- `nix eval --impure --expr '(builtins.getFlake "git+file:///home/c1/dotfiles/.worktrees/axiom-audio-pulseaudio-autospawn-fix").nixosConfigurations.axiom.config.home-manager.users.c1.home.file.".config/pulse/client.conf".text'`
- `nix eval --impure --expr '(builtins.getFlake "git+file:///home/c1/dotfiles/.worktrees/axiom-audio-pulseaudio-autospawn-fix").nixosConfigurations.axiom.config.home-manager.users.c1.home.file.".config/pulse/client.conf".force'`
- `nix eval --impure .#nixosConfigurations.axiom.config.system.build.toplevel.drvPath`
- `nix build --impure --dry-run .#nixosConfigurations.axiom.config.system.build.toplevel`
- Runtime: no real `pulseaudio` process; desktop Pulse server is `PulseAudio (on PipeWire 1.4.9)`; default sink is `alsa_output.pci-0000_01_00.1.hdmi-stereo`; `wpctl status` shows Cyberpunk routed to `MPG272UX OLED`.

## Legion Evidence

- `.legion/tasks/axiom-audio-pulseaudio-autospawn-fix/plan.md`
- `.legion/tasks/axiom-audio-pulseaudio-autospawn-fix/docs/test-report.md`
- `.legion/tasks/axiom-audio-pulseaudio-autospawn-fix/docs/review-change.md`
- `.legion/tasks/axiom-audio-pulseaudio-autospawn-fix/docs/report-walkthrough.md`
