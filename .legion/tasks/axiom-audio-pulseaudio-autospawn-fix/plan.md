# Axiom Audio PulseAudio Autospawn Fix

## 目标

Prevent axiom from losing HDMI audio because a real PulseAudio daemon autospawns and holds the NVIDIA `hdmi:0` ALSA device before PipeWire can create the real HDMI sink.

## 问题陈述

Axiom was configured to prefer the NVIDIA HDMI sink at session startup, but the no-audio failure reproduced in a live graphical session. Runtime inspection showed PipeWire, WirePlumber, and pipewire-pulse were healthy, while `wpctl status` exposed only the EasyEffects virtual sink. PipeWire logs reported `hdmi:0` as busy, and a stray `pulseaudio --start` process was running outside PipeWire. Killing that process and restarting WirePlumber recreated `alsa_output.pci-0000_01_00.1.hdmi-stereo`; stopping EasyEffects moved the active Cyberpunk 2077 stream directly to `MPG272UX OLED` and restored sound.

## 验收标准

- [ ] Axiom declaratively disables PulseAudio client autospawn for the user session so plain libpulse clients do not start a real `pulseaudio` daemon.
- [ ] The existing Axiom HDMI readiness script clears any stray real `pulseaudio` process before forcing the NVIDIA HDMI profile/default sink.
- [ ] The runtime session has no `pulseaudio --start` process and `wpctl status` shows `HDA NVidia 数字立体声 (HDMI)` as the default sink.
- [ ] Nix evaluation/build dry-run for `.#nixosConfigurations.axiom.config.system.build.toplevel` succeeds.
- [ ] Legion verification, review, walkthrough, and wiki writeback evidence are recorded.

## 假设 / 约束 / 风险

- **假设**: Axiom should continue using PipeWire, WirePlumber, pipewire-pulse, and the NVIDIA DP/HDMI audio path to the monitor output.
- **假设**: The real PulseAudio daemon is not intended to run on this host because PipeWire provides the PulseAudio-compatible server.
- **约束**: Keep the fix host-specific to `hosts/axiom/default.nix`.
- **约束**: Do not remove EasyEffects or redesign the broader audio stack in this follow-up.
- **约束**: Use Legion task docs and the worktree/PR delivery path for repository changes.
- **风险**: Killing `pulseaudio` in the readiness script is safe only because this host intentionally uses PipeWire's Pulse server.
- **风险**: Runtime verification proves the current session, but a future desktop startup race can still require checking service ordering if the failure changes shape.

## 范围

- Axiom host configuration for PulseAudio autospawn prevention.
- Axiom host HDMI readiness script hardening.
- Immediate runtime confirmation that the current session remains on the real HDMI sink.
- Task-local Legion evidence and delivery artifacts.

## 非范围

- Generic audio module redesign.
- Removing or replacing EasyEffects.
- Changing audio routing on non-Axiom hosts.
- Changing application-specific audio settings for games, browsers, Steam, or Wine.

## 推荐方向

Keep the existing Axiom HDMI readiness unit and add two narrow safeguards: disable PulseAudio client autospawn through `home.configFile."pulse/client.conf"`, and make the readiness script `pkill -x pulseaudio` before reselecting the HDMI profile. This addresses the observed root cause without broadening the audio stack changes.

## 阶段概览

1. **Contract and worktree** - Create this Legion follow-up task and isolated worktree.
2. **Implementation** - Apply the minimal Axiom host configuration change.
3. **Verification** - Confirm Nix evaluation/dry-run and live audio state.
4. **Delivery** - Run readiness review, walkthrough, wiki writeback, and PR lifecycle.

---

*创建于: 2026-06-16 | 最后更新: 2026-06-16*
