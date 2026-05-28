# Axiom HDMI Audio Startup Fix

## 目标

Make axiom persistently route Zen and Sidra audio through the NVIDIA DP/HDMI output to the DELL U2720QM headphone jack after graphical session startup.

## 问题陈述

The no-audio incident has reproduced twice. Direct ALSA playback to hdmi:CARD=NVidia,DEV=0 works, but GUI apps attach to the PipeWire/Pulse Easy Effects virtual sink while the real NVIDIA HDMI sink can be missing until the card profile is reselected. Restarting/reselecting the HDMI profile recreates the sink and restores audio, so the fix should make session startup create and prefer the real HDMI sink before EasyEffects/app streams depend on it.

## 验收标准

- [ ] Axiom graphical sessions create the NVIDIA HDMI sink for DELL U2720QM without manual pactl profile toggling.
- [ ] The default PipeWire/Pulse sink is alsa_output.pci-0000_01_00.1.hdmi-stereo for axiom.
- [ ] EasyEffects may remain installed and running, but it must not leave Zen/Sidra attached to a virtual sink without a working HDMI backend.
- [ ] nix build --impure --no-link .#nixosConfigurations.axiom.config.system.build.toplevel passes or any unrelated pre-existing failure is documented.
- [ ] Legion task docs record verification, review, walkthrough, wiki writeback, and submission evidence.

## 假设 / 约束 / 风险

- **假设**: Axiom should continue using the NVIDIA DP/HDMI audio path to the DELL U2720QM monitor headphone output.
- **假设**: EasyEffects is optional processing, not the source of truth for output device selection.
- **假设**: The host-specific PCI sink name alsa_output.pci-0000_01_00.1.hdmi-stereo is stable enough for axiom because it is already referenced in host-specific WirePlumber priority config.
- **约束**: Keep the fix host-specific to axiom unless a generic audio-module ordering fix is clearly safe.
- **约束**: Do not remove PipeWire, WirePlumber, pipewire-pulse, or EasyEffects from the profile.
- **约束**: Prefer declarative Nix/systemd user configuration over runtime shell repair commands.
- **约束**: Use an isolated worktree and Legion submission flow for repository changes.
- **风险**: Forcing the HDMI profile too early may race PipeWire/WirePlumber startup unless ordered after the user audio services.
- **风险**: Toggling the card profile can interrupt already-running audio if the service is restarted during an active session.
- **风险**: Nix build success cannot fully prove runtime audio routing without a live session check.

## 要点

- This is a small host-specific reliability fix rather than a broader audio-stack redesign.
- Runtime evidence shows the HDMI hardware path works and the failure is in session routing/startup ordering.

## 范围

- Axiom host audio startup/default-sink configuration.
- EasyEffects service ordering only if needed to prevent the startup race.
- Task-local Legion evidence and delivery artifacts.
- Non-goals: no broader audio-stack redesign; no removal of EasyEffects or browser packages; no non-axiom host changes unless required for evaluation safety; no imperative one-off runtime fix as the final answer.

## 设计索引 (Design Index)

> **Design Source of Truth**: （暂无）

**摘要**:
- Add a host-specific systemd user oneshot that runs after PipeWire, pipewire-pulse, and WirePlumber to reselect the NVIDIA HDMI profile and set the HDMI sink as the default.
- Order EasyEffects after that host-specific HDMI readiness step so its virtual sink can connect to the real hardware output instead of becoming the only available sink.
- Keep existing WirePlumber priority rules for the HDMI sink and validate the evaluated systemd user units plus an axiom toplevel build.

## 阶段概览

1. **Contract and worktree** - Create the Legion task contract and isolated PR worktree.
2. **Implementation** - Implement the minimal Nix configuration change for axiom audio startup ordering.
3. **Verification** - Run Nix formatting/evaluation/build verification and record evidence.
4. **Delivery** - Run readiness review, walkthrough, wiki writeback, commit/submit, and cleanup.

---

*创建于: 2026-05-28 | 最后更新: 2026-05-28*
